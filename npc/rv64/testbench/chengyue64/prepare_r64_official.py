#!/usr/bin/env python3
"""Build the preserved RV64 p-mode ISA cohort in an isolated output directory."""
import argparse,pathlib,subprocess,struct
p=argparse.ArgumentParser()
p.add_argument('--out',type=pathlib.Path,required=True)
p.add_argument('--jobs',type=int,default=4)
a=p.parse_args();out=a.out.resolve();out.mkdir(parents=True,exist_ok=True)
root=pathlib.Path(__file__).resolve().parents[4]
isa=root/'npc/rv64/testsuites/core-tests/src/riscv-tests/isa'
elfs=out/'elfs';bins=out/'bins';elfs.mkdir(exist_ok=True);bins.mkdir(exist_ok=True)
groups='rv64ui rv64uc rv64um rv64ua rv64uf rv64ud rv64uzba rv64uzbb rv64uzbc rv64uzbs rv64si rv64mi'.split()
recipe=out/'Makefile'
contents='RISCV_GCC_OPTS := -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none\n'
contents+='include '+str(isa/'Makefile')+'\nr64_cohort_tests := '+' '.join('$('+g+'_p_tests)' for g in groups)+'\n'
contents+='.PHONY: r64-cohort\nr64-cohort: $(r64_cohort_tests)\n$(r64_cohort_tests): '+str(recipe)+'\n'
if not recipe.exists() or recipe.read_text()!=contents:recipe.write_text(contents)
subprocess.run(['make','-C',str(elfs),'-f',str(recipe),'src_dir='+str(isa),'RISCV_PREFIX=riscv64-linux-gnu-','-j'+str(a.jobs),'r64-cohort'],check=True)
cases=sorted(elf for elf in elfs.iterdir() if elf.is_file() and '-p-' in elf.name)
if not cases:raise SystemExit('empty official cohort')
for elf in cases:
 header=elf.read_bytes()[:64]
 if header[:5]!=b'\x7fELF\x02' or struct.unpack_from('<Q',header,24)[0]!=0x80000000:
  raise SystemExit(str(elf)+': entry must equal the hardware reset PC 0x80000000')
 subprocess.run(['riscv64-linux-gnu-objcopy','-O','binary',str(elf),str(bins/(elf.name+'.bin'))],check=True)
print('Built',len(cases),'official images')
