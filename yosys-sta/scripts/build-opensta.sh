#!/usr/bin/env bash
# OpenSTA 3.1.0 源码构建脚本(固化自 2026-07-08 手工流程;2026-07-10 停电丢 /tmp 产物后重写进工作区)。
# 产物: $PREFIX/OpenSTA/build/sta —— 全核 40 万 cell 秒级 STA(iEDA 全核 propagation 不收敛的旁路)。
# 依赖策略: cmake/swig 走 venv pip;eigen/CUDD 本地源码;tcl 头用系统 /usr/include/tcl。
set -euo pipefail

PREFIX=${PREFIX:-$HOME/tools}
JOBS=${JOBS:-$(nproc)}
mkdir -p "$PREFIX"
cd "$PREFIX"

# 1. venv: cmake + swig
if [[ ! -x "$PREFIX/buildenv/bin/cmake" ]]; then
  python3 -m venv buildenv
  "$PREFIX/buildenv/bin/pip" install --quiet cmake swig
fi
export PATH="$PREFIX/buildenv/bin:$PATH"

# 2. eigen (header-only, cmake install 生成 Eigen3Config.cmake 供 find_package)
if [[ ! -f "$PREFIX/eigen-install/share/eigen3/cmake/Eigen3Config.cmake" ]]; then
  [[ -d eigen-src ]] || git clone --depth 1 --branch 3.4.0 https://gitlab.com/libeigen/eigen.git eigen-src
  cmake -S eigen-src -B eigen-src/build -DCMAKE_INSTALL_PREFIX="$PREFIX/eigen-install" \
    -DEIGEN_BUILD_DOC=OFF -DBUILD_TESTING=OFF >/dev/null
  cmake --install eigen-src/build >/dev/null
fi

# 3. CUDD
if [[ ! -f "$PREFIX/cudd-install/lib/libcudd.a" ]]; then
  [[ -d cudd ]] || git clone --depth 1 https://github.com/davidkebo/cudd.git cudd-repo
  tar xf cudd-repo/cudd_versions/cudd-3.0.0.tar.gz
  cd cudd-3.0.0
  # aclocal 时间戳重生成规避(教训: 解包后 mtime 乱序触发 autotools 重跑)
  touch aclocal.m4 configure Makefile.in config.h.in
  ./configure --prefix="$PREFIX/cudd-install" >/dev/null
  make -j"$JOBS" >/dev/null && make install >/dev/null
  cd "$PREFIX"
fi

# 4. OpenSTA
if [[ ! -d OpenSTA ]]; then
  git clone --depth 1 https://github.com/parallaxsw/OpenSTA.git
fi
cd OpenSTA && mkdir -p build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCUDD_DIR="$PREFIX/cudd-install" \
  -DEigen3_DIR="$PREFIX/eigen-install/share/eigen3/cmake" \
  -DTCL_INCLUDE_PATH=/usr/include/tcl \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 >/dev/null
make -j"$JOBS"
echo "BUILT: $PREFIX/OpenSTA/build/sta"
"$PREFIX/OpenSTA/build/sta" -version
