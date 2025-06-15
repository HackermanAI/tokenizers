
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

# 0  WHITESPACE
# 1  DEFAULT
# 2  KEYWORD
# 3  CLASS
# 4  NAME
# 5  PARAMETER
# 6  LAMBDA
# 7  STRING
# 8  NUMBER
# 9  OPERATOR
# 10 COMMENT
# 11 SPECIAL
# 12 CONDITIONAL
# 13 BUILT_IN
# 14 ERROR
# 15 WARNING
# 16 SUCCESS

from main import TOKEN_MAP # token map is same for all lexers

from pygments import lex
from pygments.lexers import get_lexer_for_filename
from pygments.token import Token

# https://pygments.org/docs/tokens/#module-pygments.token

TOKEN_MAP_PYGMENTS = {
    Token.Text.Whitespace: 0,
    Token.Text: 1,
    Token.Punctuation: 1,
    Token.Generic: 1,
    Token.Other: 1,
    Token.Keyword.Constant: 2,
    Token.Keyword.Declaration: 2,
    Token.Keyword.Namespace: 2,
    Token.Keyword.Reserved: 2,
    Token.Name.Class: 3,
    Token.Name.Function: 4,
    Token.Name.Property: 5,
    Token.Literal: 7,
    Token.Literal.String.Single: 7,
    Token.Literal.String.Double: 7,
    Token.Literal.Number.Integer: 8,
    Token.Literal.Number.Float: 8,
    Token.Operator: 9,
    Token.Literal.Date: 9,
    Token.Comment.Single: 10,
    Token.Comment.Multiline: 10,
    Token.Keyword.Type: 11,
    Token.Keyword.Constant: 12,
    Token.Name.Builtin: 13,
    Token.Error: 14,
}

class Lexer(object):
    def __init__(self, filename): self.lexer = get_lexer_for_filename(filename)

    def comment_char(self): return "" # todo : create map for comment injection in common un-supported programming languages

    def lexer_name(self): return f"<{ self.lexer.name }>"
    
    def tokenize(self, text):
        tokens = []
        result = list(self.lexer.get_tokens_unprocessed(text))
        for token in result:
            token_type = str(TOKEN_MAP[TOKEN_MAP_PYGMENTS[token[1]]] if token[1] in TOKEN_MAP_PYGMENTS else TOKEN_MAP[1])
            start_pos = int(token[0])
            value = str(token[2])

            tokens.append((token_type, start_pos, value))

        return tokens
