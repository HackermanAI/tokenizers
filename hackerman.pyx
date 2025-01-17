# distutils: language=c++
# cython: language_level=3

# pip install cython
# cythonize -i hackerman.pyx
# NOTE : alias cc=gcc fixed compile issue on Macbook Pro (Intel)

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

# import os
import time

from enum import Enum
from cython.cimports.libc.stdint import int32_t

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

cdef class Token(object):
    cdef int type
    cdef int start_pos
    cdef str value

    def __init__(self, int type, int start_pos, value=None):
        self.type = type
        self.start_pos = start_pos
        self.value = value

    def __repr__(self): return str(self.value)

cdef class Lexer(object):
    cdef list NAME, HEADERS, CONDITIONAL
    
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

    def comment_char(self) -> str: return "--"

    def lexer_name(self) -> str: return "Hackerman"

    def tokenize(self, str text, highlight_todos: bool = False):
        cdef float start_time = time.time()
        cdef list tokens = []
        cdef str current_char = ''
        cdef int current_char_index = 0
        
        while current_char_index < len(text):
            current_char = text[current_char_index]

            if current_char in { ' ', '\t', '\r' }:
                current_char_index += 1
            
            elif current_char == '\n':
                current_char_index += 1
    
            # comment
            elif current_char == '-':
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
            
            # header
            elif current_char == '[':
                start_pos = current_char_index
                header = str(current_char)
                
                current_char_index += 1
                
                while current_char_index < len(text) and text[current_char_index].isprintable():
                    header += str(text[current_char_index])
                    if text[current_char_index] == ']':
                        current_char_index += 1
                        break
                    
                    current_char_index += 1

                tokens.append(Token(TokenType.KEYWORD, start_pos, header))
            
            # strings
            elif current_char in { '"', '\'' }:
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
            
            else:
                
                # number
                if current_char.isdigit():
                    start_pos = current_char_index
                    number = str(current_char)
                    current_char_index += 1
                    
                    while current_char_index < len(text) and (text[current_char_index].isdigit() or text[current_char_index].isalpha() or text[current_char_index] in ["."]):
                        number += str(text[current_char_index])
                        current_char_index += 1

                    tokens.append(Token(TokenType.NUMBER, start_pos, number))
                
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
                    # name
                    elif identifier in self.NAME:
                        tokens.append(Token(TokenType.NAME, start_pos, identifier))
                    # default
                    else:
                        tokens.append(Token(TokenType.DEFAULT, start_pos, identifier))
                else:
                    tokens.append(Token(TokenType.ERROR, current_char_index, current_char))
                    current_char_index += 1

        print("python", time.time() - start_time)

        return tokens, [], []
