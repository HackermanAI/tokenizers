odin build odin.odin -file -build-mode:dll
odin build hackerman.odin -file -build-mode:dll
odin build pc.odin -file -build-mode:dll

.venv/bin/python build.py build_ext --inplace
