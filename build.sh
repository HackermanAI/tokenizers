
# odin build odin.odin -file -build-mode:dll
# odin build hackerman.odin -file -build-mode:dll
# odin build pc.odin -file -build-mode:dll

export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
.venv/bin/python build.py build_ext --inplace
