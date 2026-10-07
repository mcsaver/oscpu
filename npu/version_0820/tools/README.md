# Persistent build dependencies

`cmake-python` and `cmake-3.31.12` hold reusable CMake installations. `llama.cpp/bin` holds the linked third-party libraries and tools used by the current backend compile. `scripts/build_llama.sh` republishes these binaries after a successful dependency build. NPU build and test intermediates may be deleted from `tmp` without deleting these dependencies.
