
# Tokenizer for Text

import re
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
                    current_char_index += 1
                case '\n':
                    current_line += 1
                    current_char_index += 1
                case '.':
                    tokens.append(Token(TokenType.KEYWORD, current_char_index, current_char))
                    current_char_index += 1
                case _:
                    tokens.append(Token(TokenType.DEFAULT, current_char_index, current_char))
                    current_char_index += 1

        return tokens, [], []
