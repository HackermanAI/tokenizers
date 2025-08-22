#!/bin/bash

if [[ $(uname) == "Darwin" ]]; then
    export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
fi

.venv/bin/python build.py build_ext --inplace
