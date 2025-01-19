
# MIT License

# Copyright 2024, 2025 @asyncze (Michael Sjöberg)

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

# Tokenizer wrapper for Hackerman DSCL (TOML-like custom DSL)

import os
import time
import ctypes

from enum import Enum

# lib_path = os.path.join(os.path.dirname(__file__), "libhackerman.dylib")
# # print(lib_path)

# lib = ctypes.CDLL(lib_path)
# lib.tokenize.argtypes = [ctypes.c_char_p] # C string
# lib.tokenize.restype = ctypes.POINTER(ctypes.c_char) # pointer to C string

# lib.free_memory.argtypes = [ctypes.POINTER(ctypes.c_char)] # free pointer to C string
# lib.free_memory.restype = None

# odin

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
        # ("type", String),
        ("type", ctypes.c_ssize_t), # todo : this fixed segmentation fault (maybe need to replace start_pos?)
        ("start_pos", ctypes.c_int),
        ("value", String),
    ]

class DynamicToken(ctypes.Structure):
    _fields_ = [
        ("data", ctypes.POINTER(Token)),
        ("len", ctypes.c_ssize_t),
        ("cap", ctypes.c_ssize_t), # this is important c_ssize_t and not c_int
    ]

lib = ctypes.CDLL(os.path.join(os.path.dirname(__file__), "hackerman_odin.dylib"))

# lib.test_tokenize.argtypes = [String]
# lib.test_tokenize.restype = DynamicToken

# test_text = "[header]\n-- comment\nfont \"Fira Code\"\nnot_name 1000"
# test_bytes = test_text.encode("utf-8")

# byte_array = (ctypes.c_uint8 * len(test_bytes))(*test_bytes)

# string_arg = String()
# string_arg.text = ctypes.cast(byte_array, ctypes.POINTER(ctypes.c_uint8))
# string_arg.len = len(test_bytes)

# lib.process_input.argtypes = [String]
# lib.process_input.restype = String

# result = lib.process_input(string_arg)

# result_string = ctypes.string_at(result.text)
# print(result_string.decode("utf-8"))

# lib.test_tokenize.argtypes = []
# lib.test_tokenize.restype = DynamicToken

# tokens = []
# result = lib.test_tokenize()
# # print(result.data, result.len)
# for n in range(result.len):
#     # print(result.data[n].type.to_python())
#     tokens.append((result.data[n].type.to_python(), result.data[n].start_pos, result.data[n].value.to_python()))

# print(tokens)

# class TokenType(str, Enum):
#     WHITESPACE  = "whitespace"
#     DEFAULT     = "default"
#     KEYWORD     = "keyword"
#     CLASS       = "class"
#     NAME        = "name"
#     PARAMETER   = "parameter"
#     LAMBDA      = "lambda"
#     STRING      = "string"
#     NUMBER      = "number"
#     OPERATOR    = "operator"
#     COMMENT     = "comment"
#     SPECIAL     = "special"
#     CONDITIONAL = "conditional"
#     BUILT_IN    = "built_in"
#     ERROR       = "error"
#     WARNING     = "warning"
#     SUCCESS     = "success"

# TOKEN_MAP = { i: token for i, token in enumerate(TokenType) }
# print(TOKEN_MAP)

from main import TOKEN_MAP

class Lexer(object):
    def __init__(self):
        self.NAME = [
            
            # editor
            
            "font",
            "font_weight",
            "font_size",
            "tab_width",
            "cursor_width",
            "margin",
            "theme",
            "file_explorer_root",
            "model_to_use",
            "eol_mode",
            
            # toggles
            
            "show_line_numbers",
            "transparent",
            "blockcursor",
            "wrap_word",
            "blinking_cursor",
            "show_scrollbar",
            "show_minimap",
            "highlight_todos",
            "whitespace_visible",
            "indent_guides",
            "highlight_current_line",
            "highlight_current_line_on_jump",
            "show_eol",
            
            # ollama
            # openai
            
            "model",
            "key",
            
            # bindings
            
            "save_file",
            "new_file",
            "new_window",
            "open_file",
            "fold_all",
            "command_k",
            "line_indent",
            "line_unindent",
            "line_comment",
            "set_bookmark",
            "open_config_file",
            "build_and_run",
            "move_to_line_start",
            "move_to_line_start_with_select",
            "zoom_in",
            "zoom_out",
            "toggle_file_explorer",
            "split_view",
            
            # todos
            
            "find_in_file",
            "undo",
            "redo",
            
            # theme
            
            "background",
            "foreground",
            "selection",
            "selection_inactive",
            "text_color",
            "text_highlight",
            "cursor",
            "whitespace",
            
            # syntax colors
            
            "default",
            "keyword",
            "class",
            "name",
            "parameter",
            "lambda",
            "string",
            "number",
            "operator",
            "comment",
            "error",
            "warning",
            "success",
            "special",
            "conditional",
            "built_in"
        ]
        self.HEADERS = [
            "editor",
            "ollama"
        ]
        self.CONDITIONAL = [
            "true",
            "false"
        ]

    def comment_char(self): return "--"

    def lexer_name(self): return "Hackerman"

    def tokenize(self, text):
        # odin
        # --------------------------------------
        lib.process_input.argtypes = [String]
        lib.process_input.restype = DynamicToken

        # text input
        text_as_bytes = text.encode("utf-8")
        text_byte_array = (ctypes.c_uint8 * len(text_as_bytes))(*text_as_bytes)
        
        text_string_arg = String()
        text_string_arg.text = ctypes.cast(text_byte_array, ctypes.POINTER(ctypes.c_uint8))
        text_string_arg.len = len(text_as_bytes)

        result = lib.process_input(text_string_arg)
        # print("result len", result.len)
        
        tokens = []
        for n in range(result.len):
            value_as_string = result.data[n].value.to_python()
            
            # find todo and note in comments
            if result.data[n].type == 10 and " todo :" in value_as_string:
                tokens.append((TOKEN_MAP[10], result.data[n].start_pos, value_as_string[:2]))
                tokens.append((TOKEN_MAP[11], result.data[n].start_pos + len(value_as_string[:2]), value_as_string[2:])) # special
            elif result.data[n].type == 10 and " note :" in value_as_string:
                tokens.append((TOKEN_MAP[10], result.data[n].start_pos, value_as_string[:2]))
                tokens.append((TOKEN_MAP[15], result.data[n].start_pos + len(value_as_string[:2]), value_as_string[2:])) # warning
            else:
                tokens.append((TOKEN_MAP[result.data[n].type], result.data[n].start_pos, value_as_string))

        return tokens
