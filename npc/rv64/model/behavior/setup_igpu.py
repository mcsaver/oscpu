#!/usr/bin/env python3
"""Prepare local Linux tools for WSL's existing Intel iGPU; no driver/security changes."""
import argparse,json,subprocess,tarfile,tempfile,urllib.request
from pathlib import Path
import sys
sys.dont_write_bytecode=True
from d3d12_backend import BUILD,build_runner
DXC_URL="https://github.com/microsoft/DirectXShaderCompiler/releases/download/v1.8.2505.1/linux_dxc_2025_07_14.x86_64.tar.gz"
HEADERS="directx-headers-dev=1.614.1-1~ubuntu0.24.04.2"

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("--build",type=Path,default=BUILD)
    a=p.parse_args();build=a.build.resolve();deps=build/"deps";deps.mkdir(parents=True,exist_ok=True)
    if not Path("/dev/dxg").exists() or not Path("/usr/lib/wsl/lib/libd3d12.so").exists():
        raise RuntimeError("WSL Direct3D12 interface is unavailable")
    with tempfile.TemporaryDirectory(prefix="r64-igpu-dependencies-") as directory:
        temp=Path(directory)
        if not (deps/"headers/usr/include/directx/d3d12.h").exists():
            subprocess.run(["apt-get","download",HEADERS],cwd=temp,check=True)
            packages=list(temp.glob("directx-headers-dev*.deb"))
            if len(packages)!=1:raise RuntimeError("expected one DirectX header package")
            subprocess.run(["dpkg-deb","-x",str(packages[0]),str(deps/"headers")],check=True)
        if not (deps/"dxc/bin/dxc").exists():
            archive=temp/"dxc.tar.gz";urllib.request.urlretrieve(DXC_URL,archive)
            with tarfile.open(archive) as t:t.extractall(deps/"dxc",filter="data")
    build_runner(build)
    provenance={"dxc":DXC_URL,"headers_package":HEADERS,
                "runtime":"existing /usr/lib/wsl/lib/libd3d12.so and libdxcore.so",
                "native_linux_only":True,"system_package_installation":False}
    (deps/"sources.json").write_text(json.dumps(provenance,indent=2)+"\n")
    print(json.dumps({"runner":str(build/"d3d12-run"),"compiler":str(deps/"dxc/bin/dxc")}))
if __name__=="__main__":main()
