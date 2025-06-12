
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

# Tokenizer for Plain Text

# cython: language_level=3
cimport cython

cdef str DEFAULT = "default"

cdef int handle_whitespace(int current_char_index):
    current_char_index += 1
    return current_char_index

@cython.cclass
class Lexer:
    
    @property
    def lexer_name(self): return "Plain Text"

    @property
    def comment_char(self): return ""

    def tokenize(self, str text):
        cdef int current_char_index = 0
        cdef str current_char
        cdef list tokens = []
        cdef int new_line = True

        while current_char_index < len(text):
            current_char = text[current_char_index]
            next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else ""

            # whitespace
            if current_char in (' ', '\t', '\r'): current_char_index = handle_whitespace(current_char_index)
            # newline
            elif current_char in ('\n'):
                current_char_index = handle_whitespace(current_char_index)
                new_line = True
                continue
            else:
                tokens.append((DEFAULT, current_char_index, current_char))
                current_char_index += 1

            new_line = False

        return tokens
