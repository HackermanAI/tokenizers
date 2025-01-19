
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

# Tokenizer for TOML

from main import TOKEN_MAP # token map is same for all lexers

from pygments import lex
from pygments.lexers import TOMLLexer
from pygments.token import Token

class Lexer(object):
    def __init__(self): pass

    def comment_char(self): return "#"

    def lexer_name(self): return "TOML"
    
    def tokenize(self, text):
        lexer = TOMLLexer()
        tokens = list(lex(text, lexer))

        for token_type, token_value in tokens:
            print(token_type, token_value)

        return tokens
