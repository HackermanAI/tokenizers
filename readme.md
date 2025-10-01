

# Tokenizers for Hackerman Text

This repo supports the bring-your-own-lexer feature in Hackerman Text code editor.

It's primarily used to support naive syntax highlightning of unsupported languages, DSL, or your own hobby languages (or esolangs).

**Note that Cython tokenizers will not be as performant as built-in lexers written in C++.**


## Getting started

See examples on how to implement a new tokenizer.

The token CONSTANTS at top of file should correspond with colors used in your theme in the Hackerman Text config file (.hackerman). You can add or remove any color CONSTANTS as long as the theme file stays consistent.

### MacOS

The binary (your-tokenizer-for-lang.so) should be placed in the Application Support/Hackerman Text/tokenziers folder.


## Example build file for Cython (.pyx)

	from setuptools import setup, Extension
	from Cython.Build import cythonize

	setup(
	    ext_modules=cythonize(
	        [
	            Extension("txt", ["txt.pyx"], extra_compile_args=["-O3", "-std=c11"]),
	            Extension("hackerman", ["hackerman.pyx"], extra_compile_args=["-O3", "-std=c11"]),
	            Extension("scrpd", ["scrpd.pyx"], extra_compile_args=["-O3", "-std=c11"]),
	            Extension("todo", ["todo.pyx"], extra_compile_args=["-O3", "-std=c11"]),
	            Extension("odin", ["odin.pyx"], extra_compile_args=["-O3", "-std=c11"]),
	        ], 
	        compiler_directives={ "language_level": "3" },
	    )
	)


# Example `.sh` build script

	#!/bin/bash

	if [[ $(uname) == "Darwin" ]]; then
	    export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
	fi

	.venv/bin/python build.py build_ext --inplace
