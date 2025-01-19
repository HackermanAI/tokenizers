
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
from pygments.lexers import TOMLLexer
from pygments.token import Token

TOKEN_MAP_PYGMENTS = {
    Token.Text.Whitespace: 0,
    Token.Punctuation: 1,
    Token.Keyword: 2,
    Token.Name: 4,
    Token.Literal.String.Double: 7,
    Token.Literal.Number.Integer: 8,
    Token.Literal.Number.Float: 8,
    Token.Operator: 9,
    Token.Literal.Date: 9,
    Token.Comment.Single: 10,
    Token.Keyword.Constant: 12,
}

class Lexer(object):
    def __init__(self): pass

    def comment_char(self): return "#"

    def lexer_name(self): return "TOML"
    
    def tokenize(self, text):
        tokens = []

        # todo : use pygments for quick lexer (might not be performant on larger files)
        lexer = TOMLLexer()
        
        result = list(lexer.get_tokens_unprocessed(text))
        for token in result:
            token_type = str(TOKEN_MAP[TOKEN_MAP_PYGMENTS[token[1]]] if token[1] in TOKEN_MAP_PYGMENTS else TOKEN_MAP[1])
            start_pos = int(token[0])
            value = str(token[2])

            tokens.append((token_type, start_pos, value))

        return tokens
