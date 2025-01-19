
# MIT License

# Copyright 2025 @asyncze (Michael Sjöberg)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Tokenizer wrapper for odin_odin.dylib

import os
import time
import ctypes

class String(ctypes.Structure):
    _fields_ = [
        ("text", ctypes.POINTER(ctypes.c_uint8)),
        ("len", ctypes.c_ssize_t),
    ]

    def to_python(self):
        if self.text:
            return ctypes.string_at(self.text).decode("utf-8")
        return ""

class Token(ctypes.Structure):
    _fields_ = [
        ("type", String),
        ("start_pos", ctypes.c_int),
        ("value", String),
    ]

class DynamicToken(ctypes.Structure):
    _fields_ = [
        ("data", ctypes.POINTER(Token)),
        ("len", ctypes.c_ssize_t),
        ("cap", ctypes.c_ssize_t), # this is important c_ssize_t and not c_int
    ]

lib = ctypes.CDLL(os.path.join(os.path.dirname(__file__), "odin_odin.dylib"))

class Lexer(object):
    def __init__(self): pass

    def comment_char(self): return "//"

    def lexer_name(self): return "Odin"

    def declarations(self): return { ":: proc", ":: struct" } # lines with these strings can be used for lookup

    def block_starters(self): return { "(", "[", "{", "\"", "\'" }

    def delimiters(self): return { "(", "[", "{", "\"", "\'" }

    def tokenize(self, text, highlight_todos=False):
        lib.process_input.argtypes = [String]
        lib.process_input.restype = DynamicToken

        text_as_bytes = text.encode("utf-8")

        byte_array = (ctypes.c_uint8 * len(text_as_bytes))(*text_as_bytes)

        string_arg = String()
        string_arg.text = ctypes.cast(byte_array, ctypes.POINTER(ctypes.c_uint8))
        string_arg.len = len(text_as_bytes)

        tokens = []
        result = lib.process_input(string_arg)
        for n in range(result.len):
            # print(result.data[n].type.to_python())
            # print(result.data[n].type.to_python(), result.data[n].start_pos, result.data[n].value.to_python())
            tokens.append((result.data[n].type.to_python(), result.data[n].start_pos, result.data[n].value.to_python()))

        return tokens
