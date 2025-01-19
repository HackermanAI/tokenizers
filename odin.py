
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

# Tokenizer wrapper for Odin

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
        ("type", ctypes.c_ssize_t),
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

        text_byte_array = (ctypes.c_uint8 * len(text_as_bytes))(*text_as_bytes)

        text_string_arg = String()
        text_string_arg.text = ctypes.cast(text_byte_array, ctypes.POINTER(ctypes.c_uint8))
        text_string_arg.len = len(text_as_bytes)

        tokens = []
        result = lib.process_input(text_string_arg)
        for n in range(result.len):
            value_as_string = result.data[n].value.to_python()
            
            # find todo and note in comments
            if result.data[n].type == 10 and " todo :" in value_as_string:
                tokens.append((TOKEN_MAP[10].value, result.data[n].start_pos, value_as_string[:2]))
                tokens.append((TOKEN_MAP[11].value, result.data[n].start_pos + len(value_as_string[:2]), value_as_string[2:])) # special
            elif result.data[n].type == 10 and " note :" in value_as_string:
                tokens.append((TOKEN_MAP[10].value, result.data[n].start_pos, value_as_string[:2]))
                tokens.append((TOKEN_MAP[15].value, result.data[n].start_pos + len(value_as_string[:2]), value_as_string[2:])) # warning
            else:
                tokens.append((TOKEN_MAP[result.data[n].type].value, result.data[n].start_pos, value_as_string))

        return tokens
