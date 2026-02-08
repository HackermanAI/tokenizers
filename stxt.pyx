
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

# Tokenizer for Super Text (Plain Text with inline shell and chat styling)

# cython: language_level=3
cimport cython

cdef str DEFAULT = "default"
cdef str INLINE_SHELL = "_inline_shell"
cdef str INLINE_CHAT = "_inline_chat"

cdef class Lexer:
    
    cdef public object shell_start
    cdef public object chat_response

    cdef readonly str lexer_name
    cdef readonly str comment_char
    cdef readonly str line_comment

    def __cinit__(self, shell_start=None, chat_response=None):
        
        # self.shell_start = shell_start or "sh:"
        # self.chat_response = chat_response or ">"
        
        
        if shell_start is None:
            self.shell_start = "sh:"
        else:
            self.shell_start = <str>shell_start if isinstance(shell_start, str) else str(shell_start)

        if chat_response is None:
            self.chat_response = ">"
        else:
            self.chat_response = <str>chat_response if isinstance(chat_response, str) else str(chat_response)
        
        self.lexer_name = u"Super Text"
        self.comment_char = u""
        self.line_comment = u""

    def colors(self):
        
        return (DEFAULT, INLINE_SHELL, INLINE_CHAT)
    
    @cython.boundscheck(False)
    @cython.wraparound(False)
    def tokenize(self, str text):
        
        cdef Py_ssize_t n = len(text)
        cdef Py_ssize_t i = 0
        cdef Py_ssize_t j
        cdef Py_ssize_t line_len
        
        cdef list tokens = []

        cdef str shell = <str>self.shell_start
        cdef Py_ssize_t shell_len = len(shell)

        cdef str chat = <str>self.chat_response
        cdef Py_ssize_t chat_len = len(chat)

        cdef str line

        while i < n:
            
            # find end of current line (excluding newline)
            j = text.find('\n', i)
            if j == -1:
                j = n

            line_len = j - i
            line = text[i:j] # does not include newline

            # decide style based on line prefix
            if shell_len and line_len >= shell_len and text.startswith(shell, i):
                tokens.append((INLINE_SHELL, i, line))
            
            # chat marker must start at column 0, supports multi-char markers too
            elif chat_len and line_len >= chat_len and text.startswith(chat, i):
                tokens.append((INLINE_CHAT, i, line))
            
            else:
                tokens.append((DEFAULT, i, line))

            # include newline as DEFAULT (keeps coverage exact and positions sane)
            if j < n:
                tokens.append((DEFAULT, j, "\n"))
                i = j + 1
            else:
                i = j

        return tokens

