
# MIT License

# Copyright 2024 @asyncze (Michael Sjöberg)

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

# Tokenizer for Hackerman DSCL (TOML-like custom DSL)

import os
import re
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

lib = ctypes.CDLL(os.path.join(os.path.dirname(__file__), "hackerman_odin.dylib"))

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


class TokenType(Enum):
    DEFAULT     = 100
    WHITESPACE  = 101
    COMMENT     = 102
    OPERATOR    = 103
    KEYWORD     = 104
    BUILT_IN    = 105
    SPECIAL     = 106
    PARAMETER   = 107
    CONDITIONAL = 108
    _ANON       = 109
    NUMBER      = 110
    STRING      = 111
    NAME        = 112
    IDENTIFIER  = 113
    FSTRING     = 114
    SPECIALC    = 115
    ERROR       = 116
    SUCCESS     = 117

class Token(object):
    def __init__(self, type, start_pos, value=None):
        self.type = type
        self.start_pos = start_pos
        self.value = value

    def __repr__(self): return str(self.value)

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
        self.NUMBER_REGEX = {
            "BINARY"    : r"^0[bB][01]+$",
            "HEX"       : r"^0[xX][0-9a-fA-F]+$",
            "OCTAL"     : r"^0[oO][0-7]+$",
            "FLOAT_SCI" : r"^\d+(\.\d+)?[eE][+-]?\d+$",
            "COMPLEX"   : r"^(\d+(\.\d+)?|\.\d+)?[+-]?\d+(\.\d+)?[jJ]$",
            "DECIMAL"   : r"^\d+(\.\d+)?$"
        }

    def comment_char(self): return "--"

    def lexer_name(self): return "Hackerman"

    def tokenize(self, text, highlight_todos=False):
        # c
        # --------------------------------------
        # start_time = time.time()

        # result = lib.tokenize(text.encode("utf-8"))
        # test = ctypes.string_at(result).decode("utf-8")
        # # lib.free_memory(result)

        # tokens = []
        # for token in test.split("\n")[1:]:
        #     values = token.split(" ", 2)
        #     token_type = TokenType[values[0].split("=")[1]]
        #     start_pos = int(values[1].split("=")[1])
        #     value = values[2].split("=")[1]

        #     tokens.append(Token(token_type, start_pos, value))

        # print("c end", time.time() - start_time)

        # odin
        # --------------------------------------
        start_time = time.time()

        # test_text = "[header]\n-- comment\nfont \"Fira Code\"\nnot_name 1000"
        text_bytes = text.encode("utf-8")
        byte_array = (ctypes.c_uint8 * len(text_bytes))(*text_bytes)

        string_arg = String()
        string_arg.text = ctypes.cast(byte_array, ctypes.POINTER(ctypes.c_uint8))
        string_arg.len = len(text_bytes)

        lib.process_input.argtypes = [String]
        lib.process_input.restype = String

        result = lib.process_input(string_arg)
        result_string = ctypes.string_at(result.text).decode("utf-8")
        # print(result_string.decode("utf-8"))

        # print(result_string.split("\n"))

        test_tokens = []
        for token in result_string.split("\n"):
            values = token.split(" ", 2)            
            if len(values) == 1 and values[0] == "": continue
            
            token_type = TokenType[values[0]]
            start_pos = int(values[1])
            value = values[2].strip()

            test_tokens.append(Token(token_type, start_pos, value))

        print("odin end", time.time() - start_time)

        # python
        # --------------------------------------
        
        start_time = time.time()
        
        tokens = []
        current_line = 1
        current_char = ''
        current_char_index = 0

        RHS = False
        current_header = None

        while current_char_index < len(text):
            current_char = text[current_char_index]
            match current_char:
                case ' ' | '\t' | '\r':
                    current_char_index += 1
                case '\n':
                    current_line += 1
                    current_char_index += 1
                    # update state
                    RHS = False
                # comment or error
                case '-':
                    next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                    if next_char == "-":
                        start_pos = current_char_index
                        current_char_index += 1
                        line = current_char
                        while current_char_index < len(text) and text[current_char_index] != '\n':
                            line += text[current_char_index]
                            current_char_index += 1
                        tokens.append(Token(TokenType.COMMENT, start_pos, line))
                    else:
                        tokens.append(Token(TokenType.ERROR, current_char_index, current_char))
                        current_char_index += 1
                # header start
                case '[':
                    start_pos = current_char_index
                    header = str(current_char)
                    
                    current_char_index += 1

                    # todo : probably no need for nested levels
                    if RHS == False:
                        nested_level = 0
                        while current_char_index < len(text) and text[current_char_index].isprintable():
                            header += str(text[current_char_index])
                            if text[current_char_index] == '[':
                                nested_level += 1
                                current_char_index += 1
                            elif text[current_char_index] == ']':
                                current_char_index += 1
                                if nested_level > 0:
                                    nested_level -= 1
                                else:
                                    break
                            else:
                                current_char_index += 1

                        current_header = header
                        tokens.append(Token(TokenType.KEYWORD, start_pos, header))
                    else:
                        tokens.append(Token(TokenType.ERROR, start_pos, current_char))    
                # strings
                case '"' | '\'':
                    start_pos = current_char_index
                    string = str(current_char)
                    
                    current_char_index += 1

                    while current_char_index < len(text) and text[current_char_index].isprintable():
                        string += str(text[current_char_index])
                        if text[current_char_index] == current_char:
                            current_char_index += 1
                            break
                        else:
                            current_char_index += 1
                    
                    tokens.append(Token(TokenType.STRING, start_pos, string))
                case _:
                    # number
                    if current_char.isdigit():
                        start_pos = current_char_index
                        number = str(current_char)
                        current_char_index += 1
                        
                        while current_char_index < len(text) and (text[current_char_index].isdigit() or text[current_char_index].isalpha() or text[current_char_index] in ["."]):
                            number += str(text[current_char_index])
                            current_char_index += 1

                        # match using regex
                        number_type = TokenType.DEFAULT
                        for type_, pattern in self.NUMBER_REGEX.items():
                            if re.match(pattern, number):
                                number_type = TokenType.NUMBER
                                break

                        if number_type == TokenType.NUMBER:
                            tokens.append(Token(TokenType.NUMBER, start_pos, number))
                        else:
                            tokens.append(Token(TokenType.ERROR, start_pos, number))
                    # identifiers
                    elif current_char.isidentifier():
                        start_pos = current_char_index
                        identifier = str(current_char)
                        current_char_index += 1
                        
                        while current_char_index < len(text) and text[current_char_index].isidentifier():
                            identifier += str(text[current_char_index])
                            current_char_index += 1

                        # conditional
                        if identifier in self.CONDITIONAL:
                            tokens.append(Token(TokenType.CONDITIONAL, start_pos, identifier))
                        # keyword
                        elif identifier in self.NAME:
                            tokens.append(Token(TokenType.NAME, start_pos, identifier))
                        # identifier
                        else:
                            tokens.append(Token(TokenType.DEFAULT, start_pos, identifier))
                    else:
                        tokens.append(Token(TokenType.ERROR, current_char_index, current_char))
                        current_char_index += 1

        print("python", time.time() - start_time)

        for n in range(len(test_tokens)):
            print(test_tokens[n].type, test_tokens[n].start_pos, test_tokens[n].value)
            print(tokens[n].type, tokens[n].start_pos, tokens[n].value)
            assert (test_tokens[n].type, test_tokens[n].start_pos, test_tokens[n].value) == (tokens[n].type, tokens[n].start_pos, tokens[n].value)

        return tokens, [], []
