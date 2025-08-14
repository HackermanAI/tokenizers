
# Build file for Cython(.pyx) files

# Cython     3.0.12
# pip        24.2
# setuptools 80.3.0

# export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
# .venv/bin/python build.py build_ext --inplace

# import sys
from setuptools import setup, Extension
from Cython.Build import cythonize

setup(ext_modules=cythonize([Extension("txt", ["txt.pyx"], ["-O3", "-std=c11"])], compiler_directives={ "language_level": "3" }))
setup(ext_modules=cythonize([Extension("hackerman", ["hackerman.pyx"], ["-O3", "-std=c11"])], compiler_directives={ "language_level": "3" }))
setup(ext_modules=cythonize([Extension("scrpd", ["scrpd.pyx"], ["-O3", "-std=c11"])], compiler_directives={ "language_level": "3" }))
setup(ext_modules=cythonize([Extension("todo", ["todo.pyx"], ["-O3", "-std=c11"])], compiler_directives={ "language_level": "3" }))
setup(ext_modules=cythonize([Extension("odin", ["odin.pyx"], ["-O3", "-std=c11"])], compiler_directives={ "language_level": "3" }))

# ext = Extension(
#     "odin",
#     sources=["odin.pyx"],
#     extra_compile_args=["-O3", "-std=c11"],
# )
# if sys.platform == "darwin":
#     ext.extra_link_args = ["-undefined", "dynamic_lookup"]

# setup(
#     name="odin",
#     ext_modules=cythonize([ext], language_level=3),
# )