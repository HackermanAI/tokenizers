
# Build file for Cython tokenizers

from setuptools import setup, Extension
from Cython.Build import cythonize

setup(
    ext_modules=cythonize(
        [
            # Extension("txt", ["txt.pyx"], extra_compile_args=["-O3", "-std=c11"]), # this is too slow on large text files to use as default for .txt
            # Extension("stxt", ["stxt.pyx"], extra_compile_args=["-O3", "-std=c11"]),
            Extension("hackerman", ["hackerman.pyx"], extra_compile_args=["-O3", "-std=c11"]),
            # Extension("scrpd", ["scrpd.pyx"], extra_compile_args=["-O3", "-std=c11"]),
            Extension("pc", ["pc.pyx"], extra_compile_args=["-O3", "-std=c11"]),
        ], 
        compiler_directives={ "language_level": "3" },
    )
)
