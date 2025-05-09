
# Build file for Cython(.pyx) files

# Cython     3.0.12
# pip        24.2
# setuptools 80.3.0

# export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
# .venv/bin/python build.py build_ext --inplace

from setuptools import setup, Extension
from Cython.Build import cythonize

setup(ext_modules=cythonize([Extension("todo", ["todo.pyx"])], compiler_directives={ "language_level": "3" }))
setup(ext_modules=cythonize([Extension("hackerman", ["hackerman.pyx"])], compiler_directives={ "language_level": "3" }))
setup(ext_modules=cythonize([Extension("scrpd", ["scrpd.pyx"])], compiler_directives={ "language_level": "3" }))
