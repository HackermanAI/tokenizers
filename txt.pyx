
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

# Tokenizer for Super Text (Plain Text with inline commands)

# cython: language_level=3
cimport cython

cdef str DEFAULT = "default"
cdef str WARNING = "warning"


cdef class Lexer:
    cdef public object cmd_start
    cdef public object cmd_end

    cdef readonly str lexer_name
    cdef readonly str comment_char
    cdef readonly str line_comment

    def __cinit__(self, cmd_start=None, cmd_end=None):
        self.cmd_start = cmd_start
        self.cmd_end = cmd_end
        
        self.lexer_name = u"Super Text"
        self.comment_char = u""
        self.line_comment = u""

    def tokenize(self, str text):
        cdef int current_char_index = 0
        cdef int text_length = len(text)
        cdef str current_char
        cdef list tokens = []

        cdef str line_buffer = ""

        while current_char_index < text_length:
            current_char = text[current_char_index]
            line_buffer += current_char

            # newline
            if current_char == '\n':
                current_char_index += 1
                # reset line buffer
                line_buffer = ""

            # whitespace
            elif current_char in (' ', '\t', '\r'):
                current_char_index += 1
            
            # command (must be at start of line buffer)
            elif current_char == self.cmd_start and line_buffer.startswith(self.cmd_start):
                start_pos = current_char_index
                current_char_index += 1 # consume command start symbol

                while current_char_index < text_length:
                    current_char = text[current_char_index]
                    
                    if current_char == '\n': # do not consume this here
                        tokens.append((WARNING, start_pos, line_buffer))
                        
                        # reset line buffer
                        line_buffer = ""
                        
                        break
                        
                    else:
                        line_buffer += current_char
                        current_char_index += 1

                # no newline
                if line_buffer != "":
                    tokens.append((WARNING, start_pos, line_buffer))
            
            # default
            else:
                tokens.append((DEFAULT, current_char_index, current_char))
                current_char_index += 1

        return tokens

