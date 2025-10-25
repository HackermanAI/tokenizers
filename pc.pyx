
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

# Tokenizer for PlayCode (.pyx)

# cython: language_level=3
cimport cython


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


KEYWORDS = { "if", "else", "while", "swap", "print" }
CONDITIONALS = { "True", "False" }


cdef inline bint _is_letter(str ch):
    return ('a' <= ch <= 'z') or ('A' <= ch <= 'Z') or (ch == '_')

cdef inline bint _is_digit(str ch):
    return '0' <= ch <= '9'

cdef inline bint _is_alnum_or_underscore(str ch):
    return _is_letter(ch) or _is_digit(ch)


cdef inline int handle_whitespace(int current_char_index):
    current_char_index += 1
    return current_char_index


cdef int handle_dash(int current_char_index, str text, list tokens):
    cdef int n = len(text)
    cdef int start = current_char_index
    cdef str lexeme

    if current_char_index + 1 < n and text[current_char_index + 1] == '-':
        lexeme = "--"
        current_char_index += 2
        
        while current_char_index < n and text[current_char_index] != '\n':
            lexeme += text[current_char_index]
            current_char_index += 1
        
        tokens.append((COMMENT, start, lexeme))
        return current_char_index
    
    elif current_char_index + 1 < n and text[current_char_index + 1] == '>':
        tokens.append((SPECIAL, start, "->"))
        return current_char_index + 2
    
    else:
        tokens.append((OPERATOR, current_char_index, "-"))
        return current_char_index + 1


cdef int handle_operator(int current_char_index, str text, list tokens):
    tokens.append((OPERATOR, current_char_index, text[current_char_index]))
    return current_char_index + 1


cdef int handle_tag(int current_char_index, str text, list tokens):
    cdef int n = len(text)
    cdef int start = current_char_index
    cdef str lexeme = "@"
    current_char_index += 1
    
    while current_char_index < n and _is_letter(text[current_char_index]):
        lexeme += text[current_char_index]
        current_char_index += 1
    
    tokens.append((LAMBDA, start, lexeme))
    return current_char_index


cdef int handle_string(int current_char_index, str text, list tokens):
    cdef int n = len(text)
    cdef int start = current_char_index
    cdef str lexeme = "\""
    current_char_index += 1
    
    while current_char_index < n and text[current_char_index] != '"':
        lexeme += text[current_char_index]
        current_char_index += 1
    
    if current_char_index < n:
        lexeme += '"'
        current_char_index += 1
    
    tokens.append((STRING, start, lexeme))
    return current_char_index


cdef int handle_number(int current_char_index, str text, list tokens):
    cdef int n = len(text)
    cdef int start = current_char_index
    cdef str lexeme = text[current_char_index]
    current_char_index += 1
    
    while current_char_index < n and (_is_digit(text[current_char_index]) or text[current_char_index] == '.'):
        lexeme += text[current_char_index]
        current_char_index += 1
    
    tokens.append((NUMBER, start, lexeme))
    return current_char_index


cdef int handle_identifier(int current_char_index, str text, list tokens):
    cdef int n = len(text)
    cdef int start = current_char_index
    cdef str lexeme = text[current_char_index]
    current_char_index += 1
    while current_char_index < n and _is_alnum_or_underscore(text[current_char_index]):
        lexeme += text[current_char_index]
        current_char_index += 1

    if lexeme in CONDITIONALS:
        tokens.append((CONDITIONAL, start, lexeme))
    
    elif lexeme in KEYWORDS:
        tokens.append((KEYWORD, start, lexeme))
    
    else:
        tokens.append((DEFAULT, start, lexeme))
    
    return current_char_index


@cython.cclass
class Lexer:

    @property
    def lexer_name(self):
        return "PlayCode"

    @property
    def comment_char(self):
        return ["--", None]

    @property
    def line_comment(self):
        return "--"

    def _is_class(self, line_text):
        return False

    def _is_function_name(self, line_text):
        if not line_text.startswith("@"):
            return False

        return [("lambda", line_text)]

    def _is_type_def(self, line_text):
        return False

    def tokenize(self, str text):
        cdef int current_char_index = 0
        cdef int n = len(text)
        cdef str ch
        cdef str next_ch
        cdef list tokens = []
        cdef bint new_line = True

        while current_char_index < n:
            ch = text[current_char_index]
            next_ch = text[current_char_index + 1] if current_char_index + 1 < n else ""

            # whitespace
            if ch in (' ', '\t', '\r'):
                current_char_index = handle_whitespace(current_char_index)
            
            # newline
            elif ch == '\n':
                current_char_index = handle_whitespace(current_char_index)
                new_line = True
                continue
            
            # '-' : comment / '->' / minus
            elif ch == '-':
                current_char_index = handle_dash(current_char_index, text, tokens)
            
            # single-char operators
            elif ch in ('=', '!', '+', '*', '/', '<', '>'):
                current_char_index = handle_operator(current_char_index, text, tokens)
            
            # '@' tag
            elif ch == '@':
                current_char_index = handle_tag(current_char_index, text, tokens)
            
            # string literal
            elif ch == '"':
                current_char_index = handle_string(current_char_index, text, tokens)
            
            # number
            elif _is_digit(ch):
                current_char_index = handle_number(current_char_index, text, tokens)
            
            # identifier
            elif _is_letter(ch):
                current_char_index = handle_identifier(current_char_index, text, tokens)
            
            # fallback
            else:
                tokens.append((DEFAULT, current_char_index, ch))
                current_char_index += 1

            new_line = False

        return tokens
