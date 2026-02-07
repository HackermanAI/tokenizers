
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

# Tokenizer for Scratch Pad (.pyx)

# cython: language_level=3
cimport cython

cdef str DEFAULT    = "default"
cdef str KEYWORD    = "keyword"
cdef str COMMENT    = "comment"
cdef str NAME       = "name"
cdef str SPECIAL    = "special"
cdef str ERROR      = "error"
cdef str SUCCESS    = "success"


cdef int handle_whitespace(int current_char_index):
    current_char_index += 1
    return current_char_index


cdef int handle_command(int current_char_index, str text, list tokens):
    cdef int start_pos = current_char_index
    cdef str line = text[current_char_index]
    current_char_index += 1

    while current_char_index < len(text) and text[current_char_index] != '\n':
        line += text[current_char_index]
        current_char_index += 1

    tokens.append((NAME, start_pos, line))
    return current_char_index


cdef int handle_chat(int current_char_index, str text, list tokens):
    cdef int start_pos = current_char_index
    cdef str line = text[current_char_index]
    current_char_index += 1

    while current_char_index < len(text) and text[current_char_index] != '\n':
        line += text[current_char_index]
        current_char_index += 1

    tokens.append((SPECIAL, start_pos, line))
    return current_char_index


cdef int handle_header(int current_char_index, str text, list tokens):
    cdef int start_pos = current_char_index
    cdef str line = text[current_char_index]
    current_char_index += 1

    while current_char_index < len(text) and text[current_char_index] != '\n':
        line += text[current_char_index]
        current_char_index += 1

    tokens.append((KEYWORD, start_pos, line))
    return current_char_index


cdef int handle_done_task(int current_char_index, str text, list tokens):
    cdef int start_pos = current_char_index
    cdef str line = text[current_char_index]
    current_char_index += 1

    while current_char_index < len(text) and text[current_char_index] != '\n':
        line += text[current_char_index]
        current_char_index += 1

    tokens.append((SUCCESS, start_pos, line))
    return current_char_index


cdef int handle_not_done_task(int current_char_index, str text, list tokens):
    cdef int start_pos = current_char_index
    cdef str line = text[current_char_index]
    current_char_index += 1

    cdef str special = ""

    while current_char_index < len(text) and text[current_char_index] != '\n':
        if text[current_char_index] == '[':
            tokens.append((NAME, start_pos, line))
            
            # update state
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
    return current_char_index


cdef int handle_priority_task(int current_char_index, str text, list tokens):
    cdef int start_pos = current_char_index
    cdef str line = text[current_char_index]
    current_char_index += 1

    while current_char_index < len(text) and text[current_char_index] != '\n':
        line += text[current_char_index]
        current_char_index += 1

    tokens.append((ERROR, start_pos, line))
    return current_char_index


@cython.cclass
class Lexer:
    
    @property
    def lexer_name(self):
        return "Scratch Pad"

    @property
    def comment_char(self):
        return ""

    @property
    def line_comment(self):
        return ""

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
            # command
            elif new_line and current_char == '>' and next_char == '>': current_char_index = handle_command(current_char_index, text, tokens)
            # chat
            elif new_line and current_char == '%' and next_char == '%': current_char_index = handle_chat(current_char_index, text, tokens)
            # header
            elif new_line and current_char == '#': current_char_index = handle_header(current_char_index, text, tokens)
            # done task
            elif new_line and current_char == '+': current_char_index = handle_done_task(current_char_index, text, tokens)
            # not done task
            elif new_line and current_char == '-': current_char_index = handle_not_done_task(current_char_index, text, tokens)
            # priority task
            elif new_line and current_char == '*': current_char_index = handle_priority_task(current_char_index, text, tokens)
            # handle identifiers
            # elif new_line and current_char.isalpha(): current_char_index = handle_identifiers(current_char_index, text, tokens)
            # style everything else as comment
            else:
                tokens.append((DEFAULT, current_char_index, current_char))
                current_char_index += 1

            new_line = False

        return tokens

