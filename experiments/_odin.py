
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
import ctypes

TOKEN_MAP = { # to map int value from Odin to style string
    0: "whitespace",
    1: "default",
    2: "keyword",
    3: "class",
    4: "name",
    5: "parameter",
    6: "lambda",
    7: "string",
    8: "number",
    9: "operator",
    10: "comment",
    11: "special",
    12: "type",
    13: "conditional",
    14: "built_in",
    # system colors
    20: "error",
    21: "warning",
    22: "success",
}

lib = ctypes.CDLL(os.path.join(os.path.dirname(__file__), "odin.dylib"))

# Odin internal struct for string (rawptr and len)
class String(ctypes.Structure):
    _fields_ = [
        ("text", ctypes.POINTER(ctypes.c_uint8)),
        ("len", ctypes.c_ssize_t),
    ]

    def to_python(self):
        if self.text: return ctypes.string_at(self.text, self.len).decode("utf-8")
        return ""

# Odin custom struct for Token
class Token(ctypes.Structure):
    _fields_ = [
        # ("type", String),
        ("type", ctypes.c_ssize_t), # todo : this fixed segmentation fault (maybe need to replace start_pos?)
        ("start_pos", ctypes.c_int),
        ("value", String),
    ]

# Odin internal struct for [dynamic]Token
class DynamicToken(ctypes.Structure):
    _fields_ = [
        ("data", ctypes.POINTER(Token)),
        ("len", ctypes.c_ssize_t),
        ("cap", ctypes.c_ssize_t), # this is important c_ssize_t and not c_int
    ]

class Lexer(object):
    @property
    def lexer_name(self): return "Odin"

    @property
    def comment_char(self): return "//"

    def declarations(self):
        return {
            "pattern": {
                ":: proc": "name", # use name as style
                ":: struct": "default" # use default as style
            },
            "token_pos": 0 # token to style is at line start (i.e. before pattern)
        }

    # def block_starters(self): return { "(", "[", "{" } # to help auto indent on block starters

    # def delimiters(self): return { "(", "[", "{", "\"", "\'" } # to auto insert closing char

    def tokenize(self, text):
        tokens = []
        
        # define arg and res types
        lib.process_input.argtypes = [String]
        lib.process_input.restype = DynamicToken

        # lib.free_tokens.argtypes = [c_void_p]
        # lib.free_tokens.restype = None

        # convert text input to Odin String structure
        text_as_bytes = text.encode("utf-8")
        text_byte_array = (ctypes.c_uint8 * len(text_as_bytes))(*text_as_bytes)

        text_string_arg = String()
        text_string_arg.text = ctypes.cast(text_byte_array, ctypes.POINTER(ctypes.c_uint8))
        text_string_arg.len = len(text_as_bytes)

        # call process_input (Odin procedure)
        result = lib.process_input(text_string_arg)

        # process result
        for n in range(result.len):
            value_as_string = result.data[n].value.to_python()

            # change some names to default
            if result.data[n].type == 4 and not (result.data[n + 2].type == 2 and result.data[n + 2].value.to_python() == "proc"):
                tokens.append(("default", result.data[n].start_pos, value_as_string))
            else:
                tokens.append((TOKEN_MAP[result.data[n].type], result.data[n].start_pos, value_as_string))

        return tokens
