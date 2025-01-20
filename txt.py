
# MIT License

# Copyright 2024, 2025 @asyncze (Michael Sjöberg)

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

# WHITESPACE  = "whitespace"
DEFAULT     = "default"
KEYWORD     = "keyword"
# CLASS       = "class"
# NAME        = "name"
# PARAMETER   = "PARAMETER"
# LAMBDA      = "lambda"
# STRING      = "string"
# NUMBER      = "number"
# OPERATOR    = "operator"
# COMMENT     = "comment"
# SPECIAL     = "special"
# CONDITIONAL = "conditional"
# BUILT_IN    = "built_in"
# ERROR       = "error"
# WARNING     = "warning"
# SUCCESS     = "success"

class Lexer(object):
    def __init__(self): pass

    def comment_char(self): return None

    def lexer_name(self): return "Plain Text"
    
    def tokenize(self, text):
        tokens = []
        current_char = ''
        current_char_index = 0

        while current_char_index < len(text):
            current_char = text[current_char_index]
            match current_char:
                # whitespace
                case ' ' | '\t' | '\r' | '\n':
                    current_char_index += 1
                # dot as keyword
                case '.':
                    tokens.append((KEYWORD, int(current_char_index), str(current_char)))
                    current_char_index += 1
                # catch-all
                case _:
                    tokens.append((DEFAULT, int(current_char_index), str(current_char)))
                    current_char_index += 1

        return tokens
