#!/usr/bin/env python3
"""Run immutable official RV64 binaries on the complete native core/reference."""
import argparse, concurrent.futures, json, pathlib, subprocess, time
p=argparse.ArgumentParser()
p.add_argument('--bin-dir',type=pathlib.Path,required=True)
p.add_argument('--elf-dir',type=pathlib.Path,required=True)
p.add_argument('--sim',type=pathlib.Path,required=True)
p.add_argument('--ref',type=pathlib.Path,required=True)
p.add_argument('--out',type=pathlib.Path,required=True)
p.add_argument('--jobs',type=int,default=4)
a=p.parse_args()
a.out=a.out.resolve();a.out.mkdir(parents=True,exist_ok=True)
a.sim=a.sim.resolve();a.ref=a.ref.resolve()
cases=sorted(a.bin_dir.resolve().glob('*.bin'))
if not cases:raise SystemExit('no official binaries found')
def run(image):
    name=image.stem
    elf=a.elf_dir.resolve()/name
    symbols=subprocess.check_output(['riscv64-linux-gnu-nm',str(elf)],text=True)
    host=[int(line.split()[0],16) for line in symbols.splitlines() if line.split()[-1:] == ['tohost']]
    if len(host)!=1:raise RuntimeError(f'{name}: missing unique ELF tohost')
    # Flat bytes are immutable baseline artifacts; verify the ELF used for
    # symbol lookup is exactly their load-image source before using its symbol.
    import tempfile
    with tempfile.NamedTemporaryFile() as converted:
        subprocess.run(['riscv64-linux-gnu-objcopy','-O','binary',str(elf),converted.name],check=True)
        if pathlib.Path(converted.name).read_bytes()!=image.read_bytes():raise RuntimeError(f'{name}: ELF/bin mismatch')
    work=a.out/name;work.mkdir(exist_ok=True)
    start=time.monotonic()
    with (work/'run.log').open('w') as log:
        try:
            rc=subprocess.run([str(a.sim),str(image),str(a.ref),f'--tohost=0x{host[0]:x}'],cwd=work,stdout=log,stderr=subprocess.STDOUT,timeout=120).returncode
        except subprocess.TimeoutExpired:rc=124
    output=(work/'run.log').read_text(errors='replace')
    ok=rc==0 and '[PASS] r64_core_program' in output
    details=[line for line in output.splitlines() if '[FAIL]' in line or '[PASS]' in line or '%Error' in line]
    return dict(name=name,status='PASS' if ok else 'FAIL',returncode=rc,seconds=round(time.monotonic()-start,3),detail=details[-2:])
results=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=a.jobs) as pool:
    for result in pool.map(run,cases):
        results.append(result)
        print(result['status'],result['name'],' | '.join(result.get('detail',[])),flush=True)
        (a.out/'summary.json').write_text(json.dumps(results,indent=2)+'\n')
counts={s:sum(r['status']==s for r in results) for s in ['PASS','FAIL','N/A']}
print(json.dumps(counts),flush=True)
raise SystemExit(bool(counts['FAIL']))
