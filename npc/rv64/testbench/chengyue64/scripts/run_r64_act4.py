#!/usr/bin/env python3
"""Native system ACT4 regression with instruction reference and real tohost."""
import argparse,concurrent.futures,json,pathlib,subprocess,time
p=argparse.ArgumentParser()
for n in ['elf-root','sim','ref','out']:p.add_argument('--'+n,type=pathlib.Path,required=True)
p.add_argument('--jobs',type=int,default=4)
a=p.parse_args();a.elf_root=a.elf_root.resolve();a.out=a.out.resolve()
a.sim=a.sim.resolve();a.ref=a.ref.resolve();a.out.mkdir(parents=True,exist_ok=True)
cases=sorted(a.elf_root.rglob('*.elf'))
if not cases:raise SystemExit('no ACT4 ELFs')
def run(elf):
    name=str(elf.relative_to(a.elf_root).with_suffix(''))
    folder=a.out/name;folder.mkdir(parents=True,exist_ok=True)
    image=folder/'image.bin'
    subprocess.run(['riscv64-linux-gnu-objcopy','-O','binary',str(elf),str(image)],check=True)
    syms=subprocess.check_output(['riscv64-linux-gnu-nm',str(elf)],text=True)
    host=[int(l.split()[0],16) for l in syms.splitlines() if l.split()[-1:]==['tohost']]
    if len(host)!=1:raise RuntimeError(name+': missing tohost')
    start=time.monotonic()
    with (folder/'run.log').open('w') as log:
        try:rc=subprocess.run([str(a.sim),str(image),str(a.ref),f'--tohost=0x{host[0]:x}','--maxcycles=5000000'],cwd=folder,stdout=log,stderr=subprocess.STDOUT,timeout=180).returncode
        except subprocess.TimeoutExpired:rc=124
    output=(folder/'run.log').read_text(errors='replace')
    details=[l for l in output.splitlines() if '[PASS]' in l or '[FAIL]' in l or '%Error' in l or 'Assertion' in l]
    return dict(name=name,status='PASS' if rc==0 and '[PASS] r64_core_program' in output else 'FAIL',returncode=rc,seconds=round(time.monotonic()-start,3),detail=details[-3:])
results=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=a.jobs) as pool:
    for r in pool.map(run,cases):
        results.append(r);print(r['status'],r['name'],' | '.join(r['detail']),flush=True)
        (a.out/'summary.json').write_text(json.dumps(results,indent=2)+'\n')
counts={s:sum(r['status']==s for r in results) for s in ['PASS','FAIL']}
print(json.dumps(counts),flush=True)
raise SystemExit(bool(counts['FAIL']))
