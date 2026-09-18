#!/usr/bin/env python3
"""Run the complete baseline AM case list on the native system and reference."""
import argparse,csv,json,pathlib,subprocess,time,concurrent.futures
p=argparse.ArgumentParser()
source=p.add_mutually_exclusive_group(required=True)
source.add_argument('--manifest',type=pathlib.Path)
source.add_argument('--tests',type=pathlib.Path)
p.add_argument('--images',type=pathlib.Path,required=True)
p.add_argument('--sim',type=pathlib.Path,required=True)
p.add_argument('--ref',type=pathlib.Path,required=True)
p.add_argument('--out',type=pathlib.Path,required=True)
p.add_argument('--jobs',type=int,default=4)
a=p.parse_args()
names=sorted(p.stem for p in a.tests.glob('*.c')) if a.tests else [r['test'] for r in csv.DictReader(a.manifest.open())]
if not names:raise SystemExit('no AM test cases')
a.out=a.out.resolve();a.out.mkdir(parents=True,exist_ok=True)
a.sim=a.sim.resolve();a.ref=a.ref.resolve();a.images=a.images.resolve()
def run(name):
    image=a.images/(name+'-riscv64-npc.bin')
    if not image.is_file():raise RuntimeError('missing image '+str(image))
    folder=a.out/name;folder.mkdir(exist_ok=True);start=time.monotonic()
    with (folder/'run.log').open('w') as log:
        try:rc=subprocess.run([str(a.sim),str(image),str(a.ref),'--maxcycles=50000000'],cwd=folder,stdout=log,stderr=subprocess.STDOUT,timeout=180).returncode
        except subprocess.TimeoutExpired:rc=124
    output=(folder/'run.log').read_text(errors='replace')
    details=[l for l in output.splitlines() if '[PASS]' in l or '[FAIL]' in l or '%Error' in l or 'Assertion' in l]
    ok=rc==0 and '[PASS] r64_core_program' in output
    return dict(name=name,status='PASS' if ok else 'FAIL',returncode=rc,seconds=round(time.monotonic()-start,3),detail=details[-3:])
results=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=a.jobs) as pool:
    for r in pool.map(run,names):
        results.append(r);print(r['status'],r['name'],' | '.join(r['detail']),flush=True)
        (a.out/'summary.json').write_text(json.dumps(results,indent=2)+'\n')
counts={s:sum(r['status']==s for r in results) for s in ['PASS','FAIL']}
print(json.dumps(counts),flush=True)
raise SystemExit(bool(counts['FAIL']))
