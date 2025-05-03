
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

# Tokenizer for Todo (.pyx-version)

# cython: language_level=3
from cpython cimport PyUnicode_FromStringAndSize
from libc.string cimport memcpy

cimport cython

cdef str DEFAULT        = "default"
cdef str KEYWORD        = "keyword"
cdef str COMMENT        = "comment"
cdef str NAME           = "name"
cdef str SPECIAL        = "special"
cdef str ERROR          = "error"
cdef str SUCCESS        = "success"

@cython.cclass
class Lexer:
    def __init__(self): pass

    def comment_char(self): return None

    def lexer_name(self): return "Todo (pyx)"

    def tokenize(self, str text):
        cdef int current_char_index = 0
        cdef int start_pos
        cdef str line
        cdef str special
        cdef str current_char
        cdef list tokens = []

        while current_char_index < len(text):
            current_char = text[current_char_index]

            # whitespace
            if current_char in (' ', '\t', '\r', '\n'):
                current_char_index += 1
                continue

            # header
            if current_char == '#':
                start_pos = current_char_index
                line = current_char
                current_char_index += 1

                while current_char_index < len(text) and text[current_char_index] != '\n':
                    line += text[current_char_index]
                    current_char_index += 1

                tokens.append((KEYWORD, start_pos, line))

            # done
            elif current_char == '+':
                start_pos = current_char_index
                line = current_char
                current_char_index += 1

                while current_char_index < len(text) and text[current_char_index] != '\n':
                    line += text[current_char_index]
                    current_char_index += 1

                tokens.append((SUCCESS, start_pos, line))

            # not done
            elif current_char == '-':
                start_pos = current_char_index
                line = current_char
                current_char_index += 1

                while current_char_index < len(text) and text[current_char_index] != '\n':
                    if text[current_char_index] == '[':
                        tokens.append((NAME, start_pos, line))
                        start_pos = current_char_index
                        special = text[current_char_index]
                        current_char_index += 1

                        while current_char_index < len(text) and text[current_char_index] != '\n':
                            special += text[current_char_index]
                            if text[current_char_index] == ']':
                                current_char_index += 1
                                break
                            current_char_index += 1

                        tokens.append((SPECIAL, start_pos, special))

                        if current_char_index < len(text) and text[current_char_index] == ' ':
                            current_char_index += 1

                        start_pos = current_char_index
                        line = ""
                    else:
                        line += text[current_char_index]
                        current_char_index += 1

                tokens.append((NAME, start_pos, line))

            # important
            elif current_char == '*':
                start_pos = current_char_index
                line = current_char
                current_char_index += 1

                while current_char_index < len(text) and text[current_char_index] != '\n':
                    line += text[current_char_index]
                    current_char_index += 1

                tokens.append((ERROR, start_pos, line))

            # style everything else as comment
            else:
                tokens.append((COMMENT, current_char_index, current_char))
                current_char_index += 1

        return tokens
