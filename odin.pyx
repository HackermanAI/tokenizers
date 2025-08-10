
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

# Tokenizer for Odin

# cython: language_level=3
cimport cython

# --- Token Types ---
cdef str WHITESPACE = "whitespace"
cdef str DEFAULT = "default"
cdef str KEYWORD = "keyword"
cdef str CLASS = "class"
cdef str NAME = "name"
cdef str PARAMETER = "parameter"
cdef str LAMBDA = "lambda"
cdef str STRING = "string"
cdef str NUMBER = "number"
cdef str OPERATOR = "operator"
cdef str COMMENT = "comment"
cdef str SPECIAL = "special"
cdef str TYPE = "type"
cdef str CONDITIONAL = "conditional"
cdef str BUILT_IN = "built_in"
# system colors
cdef str ERROR = "error"
cdef str WARNING = "warning"
cdef str SUCCESS = "success"

# --- Keyword and Built-in Sets ---
KEYWORDS = frozenset({ 
    "asm",
    "auto_cast",
    "bit_set",
    "break",
    "case",
    "cast",
    "context",
    "continue",
    "defer",
    "distinct",
    "do",
    "dynamic",
    "else",
    "enum",
    "fallthrough",
    "for",
    "foreign",
    "if",
    "import",
    "in",
    "map",
    "not_in",
    "or_else",
    "or_return",
    "package",
    "proc",
    "return",
    "struct",
    "switch",
    "transmute",
    "typeid",
    "union",
    "using",
    "when",
    "where",
})

BUILT_INS = frozenset({
    "fmt",
    "len",
    "println",
})

TYPES = frozenset({
    "i8",
    "i16",
    "i32",
    "i64",
    "i128",
    "int",
    "u8",
    "u16",
    "u32",
    "u64",
    "u128",
    "uint",
    "f32",
    "f64",
    "complex64",
    "complex128",
    "quaternion128",
    "quaternion256",
    "string",
    "rune",
    "bool",
})

# --- Helper Functions for Tokenization ---

cdef int handle_attribute(int current_char_index, str text, int length, list tokens):
    cdef int start_pos = current_char_index
    # cdef str line = text[current_char_index]
    current_char_index += 1 # Consume '@'

    while current_char_index < length and (text[current_char_index].isalnum() or text[current_char_index] in { '_', '(', ')' }):
        # line += text[current_char_index]
        current_char_index += 1

    tokens.append((OPERATOR, start_pos, text[start_pos:current_char_index]))
    return current_char_index

cdef int handle_directive(int current_char_index, str text, int length, list tokens):
    cdef int start_pos = current_char_index
    # cdef str line = text[current_char_index]
    current_char_index += 1 # Consume '#'

    while current_char_index < length and (text[current_char_index].isalnum() or text[current_char_index] == '_'):
        # line += text[current_char_index]
        current_char_index += 1

    tokens.append((KEYWORD, start_pos, text[start_pos:current_char_index]))
    return current_char_index

cdef int handle_operator(int current_char_index, str text, list tokens):
    cdef int start_pos = current_char_index
    # cdef str line = text[current_char_index]

    tokens.append((OPERATOR, start_pos, text[current_char_index]))
    return current_char_index + 1

cdef int handle_comment(int current_char_index, str text, int length, list tokens):
    cdef int start_pos = current_char_index
    # cdef str line = text[current_char_index]
    current_char_index += 1 # Consume '//'

    while current_char_index < length and text[current_char_index] != '\n':
        # line += text[current_char_index]
        current_char_index += 1

    tokens.append((COMMENT, start_pos, text[start_pos:current_char_index]))
    return current_char_index

cdef int handle_multiline_comment(int current_char_index, str text, int length, list tokens):
    cdef int start_pos = current_char_index
    # cdef str line = text[current_char_index]
    current_char_index += 1 # Consume '/*'

    while current_char_index + 1 < length:
        if text[current_char_index] == '*' and text[current_char_index + 1] == '/':
            # line += text[current_char_index]
            # line += text[current_char_index + 1]
            current_char_index += 2
            
            tokens.append((COMMENT, start_pos, text[start_pos:current_char_index]))
            return current_char_index
        
        # line += text[current_char_index]
        current_char_index += 1

    tokens.append((ERROR, start_pos, text[start_pos:current_char_index]))
    return current_char_index

cdef int handle_string(int current_char_index, str text, int length, list tokens):
    cdef int start_pos = current_char_index
    cdef str quote = text[current_char_index]
    # cdef str line = quote
    current_char_index += 1

    while current_char_index < length and text[current_char_index] != quote:
        # Handle escaped quotes
        if text[current_char_index] == '\\' and current_char_index + 1 < length:
            current_char_index += 2
        else:
            current_char_index += 1

    if current_char_index < length and text[current_char_index] == quote:
        # line += text[current_char_index]
        current_char_index += 1
        tokens.append((STRING, start_pos, text[start_pos:current_char_index]))
    else:
        # Unterminated string
        tokens.append((ERROR, start_pos, text[start_pos:current_char_index]))
    
    return current_char_index

cdef int handle_number(int current_char_index, str text, int length, list tokens):
    cdef int start_pos = current_char_index
    # cdef str line = ""

    while current_char_index < length and (text[current_char_index].isdigit() or text[current_char_index] == '.'):
        # line += text[current_char_index]
        current_char_index += 1

    tokens.append((NUMBER, start_pos, text[start_pos:current_char_index]))
    return current_char_index

cdef int handle_identifier(int current_char_index, str text, int length, list tokens):
    cdef int start_pos = current_char_index
    # cdef str line = ""

    while current_char_index < length and (text[current_char_index].isalnum() or text[current_char_index] == '_'):
        # line += text[current_char_index]
        current_char_index += 1

    cdef str identifier = text[start_pos:current_char_index]

    if identifier in KEYWORDS:
        tokens.append((KEYWORD, start_pos, identifier))
    elif identifier in BUILT_INS:
        tokens.append((BUILT_IN, start_pos, identifier))
    elif identifier in TYPES:
        tokens.append((TYPE, start_pos, identifier))
    elif identifier in { "true", "false" }:
        tokens.append((CONDITIONAL, start_pos, identifier))
    else:
        tokens.append((DEFAULT, start_pos, identifier))

    return current_char_index

@cython.cclass
class Lexer:

    @property
    def lexer_name(self):
        return "Odin"

    @property
    def comment_char(self):
        return "//"

    def tokenize(self, str text):
        cdef int current_char_index = 0
        cdef int length = len(text)
        cdef list tokens = []
        cdef str current_char
        cdef str next_char

        while current_char_index < length:
            current_char = text[current_char_index]

            # whitespace
            if current_char in { ' ', '\t', '\r', '\n' }:
                current_char_index += 1
                continue

            next_char = text[current_char_index + 1] if current_char_index + 1 < length else ""

            # attribute
            if current_char == '@':
                current_char_index = handle_attribute(current_char_index, text, length, tokens)
            # directive
            elif current_char == '#':
                current_char_index = handle_directive(current_char_index, text, length, tokens)
            # comment
            elif current_char == '/' and next_char == '/':
                current_char_index = handle_comment(current_char_index, text, length, tokens)
            # multiline comment
            elif current_char == '/' and next_char == '*':
                current_char_index = handle_multiline_comment(current_char_index, text, length, tokens)
            # scope
            elif current_char == ':' and next_char == ':':
                tokens.append((KEYWORD, current_char_index, current_char + next_char))
                current_char_index += 2
            # range
            elif current_char == '.' and next_char == '.':
                tokens.append((OPERATOR, current_char_index, current_char + next_char))
                current_char_index += 2
            # operator
            elif current_char in { '=', '!', '^', '?', '+', '-', '*', '%', '&', '|', '~', '<', '>', '/', ':' }:
                current_char_index = handle_operator(current_char_index, text, tokens)            
            # string
            elif current_char in { '\"', '\'', '`' }:
                current_char_index = handle_string(current_char_index, text, length, tokens)
            # number
            elif current_char.isdigit():
                current_char_index = handle_number(current_char_index, text, length, tokens)
            # identifier
            elif current_char.isalpha() or current_char == '_':
                current_char_index = handle_identifier(current_char_index, text, length, tokens)
            # default
            else:
                tokens.append((DEFAULT, current_char_index, current_char))
                current_char_index += 1

        return tokens
