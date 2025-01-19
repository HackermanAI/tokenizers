
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

# (non?)-Tokenizer for Plain Text

# import re
from enum import Enum

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

class Token(object):
    def __init__(self, type, start_pos, value=None):
        self.type = type
        self.start_pos = start_pos
        self.value = value

    def __repr__(self): return str(self.value)

class Lexer(object):
    def __init__(self): pass

    def comment_char(self): return None

    def lexer_name(self): return "Plain Text"

    def tokenize(self, text, highlight_todos=False):
        tokens = []
        current_line = 1
        current_char = ''
        current_char_index = 0

        while current_char_index < len(text):
            current_char = text[current_char_index]
            match current_char:
                case ' ' | '\t' | '\r':
                    # tokens.append(Token(TokenType.WHITESPACE, current_char_index, current_char))
                    current_char_index += 1
                case '\n':
                    # tokens.append(Token(TokenType.WHITESPACE, current_char_index, current_char))
                    current_line += 1
                    current_char_index += 1
                case '.':
                    tokens.append(Token(TokenType.KEYWORD, current_char_index, current_char))
                    current_char_index += 1
                case _:
                    tokens.append(Token(TokenType.DEFAULT, current_char_index, current_char))
                    current_char_index += 1

        return tokens, [], []
