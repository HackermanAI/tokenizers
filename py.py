
# MIT License

# Copyright 2024 @asyncze (Michael Sjöberg)

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

# Tokenizer for Python 3

import re
from enum import Enum

# these enums are language dependent so no need to match with colors ids in .hackerman config file
class TokenType(Enum):
    DEFAULT     = 100
    WHITESPACE  = 101
    COMMENT     = 102
    OPERATOR    = 103
    KEYWORD     = 104
    BUILT_IN    = 105
    SPECIAL     = 106
    PARAMETER   = 107
    CONDITIONAL = 108
    _ANON       = 109
    NUMBER      = 110
    STRING      = 111
    NAME        = 112
    IDENTIFIER  = 113
    FSTRING     = 114
    CLASS       = 115
    # SPECIALC    = 115

class Token(object):
    def __init__(self, type, start_pos, value=None):
        self.type = type
        self.start_pos = start_pos
        self.value = value

    def __repr__(self): return str(self.value)

class Lexer(object):
    def __init__(self):
        self.KEYWORDS = [
            "in",           "is",           "async",        "await",
            "break",        "match",        "case",         "continue",
            "elif",         "else",         "except",       "finally",
            "for",          "from",         "global",       "if",
            "import",       "nonlocal",     "pass",         "raise",
            "return",       "try",          "while",        "with",
            "yield",        "def",          "class",        "and",
            "or",           "not",
        ]
        # https://docs.python.org/3/library/functions.html
        self.BUILT_INS = [
            "assert",       "del",          "print",        "__init__",
            "super",        "len",          "abs",          "aiter",
            "all",          "anext",        "any",          "ascii",
            "bin",          "breakpoint",   "callable",     "chr",
            "classmethod",  "compile",      "delattr",      "dir",
            "divmod",       "enumerate",    "eval",         "exec",
            "filter",       "format",       "getattr",      "globals",
            "hasattr",      "hash",         "help",         "hex",
            "id",           "input",        "isinstance",   "issubclass",
            "iter",         "locals",       "map",          "max",
            "min",          "next",         "object",       "oct",
            "open",         "ord",          "pow",          "property",
            "range",        "repr",         "reversed",     "round",
            "setattr",      "slice",        "sorted",       "staticmethod",
            "sum",          "vars",         "zip"
        ]
        # data types
        self.SPECIALS = [
            "self",         "type",         "int",          "float",
            "complex",      "str",          "bool",         "dict",
            "tuple",        "list",         "frozenset",    "bytes",
            "bytearray",    "memoryview"
        ]
        # todo : rename this to special2? (default blue is special1 for class stuff)
        self.FUNC_PARAMS = [
            "lambda"
        ]
        self.CONSTANTS = [
            "True",
            "False",
            "None"
        ]
        self.NUMBER_REGEX = {
            "BINARY"        : r"^0[bB][01]+$",
            "HEX"           : r"^0[xX][0-9a-fA-F]+$",
            "OCTAL"         : r"^0[oO][0-7]+$",
            "FLOAT_SCI"     : r"^\d+(\.\d+)?[eE][+-]?\d+$",
            "COMPLEX"       : r"^(\d+(\.\d+)?|\.\d+)?[+-]?\d+(\.\d+)?[jJ]$",
            "DECIMAL"       : r"^\d+(\.\d+)?$"
        }
        self.FSTRING_REGEX = {
            "STRING_TEXT"   : r"[^{}\\]+",
            "EXPRESSION"    : r"(?<!{){([^}]*)}(?!})",
            "ESCAPE_SEQ"    : r"\\."
        }
        self.CLASS_DIR = []
        self.FUNCTION_DIR = []

    def comment_char(self): return "#"

    def function_decl(self): return "def"

    def class_decl(self): return "class"

    def lexer_name(self): return "Python 3"

    def tokenize(self, text, highlight_todos=False):
        tokens = []
        current_line = 1
        current_char = ''
        current_char_index = 0

        function_declaration = False
        # use numerical to only match non-nested groups
        function_parameters = 0
        function_arguments = 0

        skip_next_parameter = False

        inside_import = False
        inside_import_block = False

        # reset dirs
        self.CLASS_DIR = []
        self.FUNCTION_DIR = []

        while current_char_index < len(text):
            current_char = text[current_char_index]
            match current_char:
                case ' ' | '\t' | '\r':
                    current_char_index += 1
                case '\n':
                    current_line += 1
                    current_char_index += 1

                    if inside_import == True and not inside_import_block == True: inside_import = False
                case '#':
                    start_pos = current_char_index
                    current_char_index += 1
                    line = current_char
                    while current_char_index < len(text) and text[current_char_index] != '\n':
                        line += text[current_char_index]
                        current_char_index += 1
                    # todo comment is special
                    if highlight_todos and line.startswith("# todo "):
                        tokens.append(Token(TokenType.SPECIAL, start_pos, line))
                    else:
                        tokens.append(Token(TokenType.COMMENT, start_pos, line))
                case '.':
                    # triple dot is special
                    next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                    next_next_char = text[current_char_index + 2] if current_char_index + 2 < len(text) else None
                    if next_char == '.' and next_next_char == '.':
                        tokens.append(Token(TokenType.SPECIAL, current_char_index, "..."))
                        current_char_index += 3
                    # single dot is keyword
                    else:
                        tokens.append(Token(TokenType.KEYWORD, current_char_index, current_char))
                        current_char_index += 1
                case '^' | '&' | '|' | '~':
                    tokens.append(Token(TokenType.OPERATOR, current_char_index, current_char))
                    current_char_index += 1
                case '+':
                    next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                    if next_char == '=':
                        tokens.append(Token(TokenType.OPERATOR, current_char_index, "+="))
                        current_char_index += 2
                    else:
                        tokens.append(Token(TokenType.OPERATOR, current_char_index, current_char))
                        current_char_index += 1
                case '-':
                    next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                    if next_char == '=':
                        tokens.append(Token(TokenType.OPERATOR, current_char_index, "-="))
                        current_char_index += 2
                    elif next_char == '>':
                        tokens.append(Token(TokenType.DEFAULT, current_char_index, "->"))
                        current_char_index += 2
                    else:
                        tokens.append(Token(TokenType.OPERATOR, current_char_index, current_char))
                        current_char_index += 1
                case '*':
                    next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                    if next_char == '*':
                        next_next_char = text[current_char_index + 2] if current_char_index + 2 < len(text) else None
                        if next_next_char == '=':
                            tokens.append(Token(TokenType.OPERATOR, current_char_index, "**="))
                            current_char_index += 3
                        else:
                            tokens.append(Token(TokenType.OPERATOR, current_char_index, "**"))
                            current_char_index += 2
                    elif next_char == '=':
                        tokens.append(Token(TokenType.OPERATOR, current_char_index, "*="))
                        current_char_index += 2
                    else:
                        tokens.append(Token(TokenType.OPERATOR, current_char_index, current_char))
                        current_char_index += 1
                case '/':
                    next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                    if next_char == '/':
                        next_next_char = text[current_char_index + 2] if current_char_index + 2 < len(text) else None
                        if next_next_char == '=':
                            tokens.append(Token(TokenType.OPERATOR, current_char_index, "//="))
                            current_char_index += 3
                        else:
                            tokens.append(Token(TokenType.OPERATOR, current_char_index, "//"))
                            current_char_index += 2
                    elif next_char == '=':
                        tokens.append(Token(TokenType.OPERATOR, current_char_index, "/="))
                        current_char_index += 2
                    else:
                        tokens.append(Token(TokenType.OPERATOR, current_char_index, current_char))
                        current_char_index += 1
                case '%':
                    next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                    if next_char == '=':
                        tokens.append(Token(TokenType.OPERATOR, current_char_index, "%="))
                        current_char_index += 2
                    else:
                        tokens.append(Token(TokenType.OPERATOR, current_char_index, current_char))
                        current_char_index += 1
                case '(':                
                    tokens.append(Token(TokenType._ANON, current_char_index, current_char))
                    current_char_index += 1
                    # update state for custom function declaration styling
                    if function_declaration: function_parameters += 1
                    # update state for custom function name styling
                    if len(tokens) > 1 and tokens[-2].type == TokenType.IDENTIFIER: tokens[-2].type = TokenType.NAME
                    # update state for custom function arguments styling
                    if len(tokens) > 1 and tokens[-2].type == TokenType.NAME: function_arguments += 1

                    if inside_import == True: inside_import_block = True
                case ')':
                    tokens.append(Token(TokenType._ANON, current_char_index, current_char))
                    current_char_index += 1
                    # update state for custom function declaration styling
                    if function_declaration and function_parameters > 0: function_parameters -= 1 if function_parameters > 0 else 0
                    # update state for custom function arguments styling
                    if function_arguments > 0: function_arguments -= 1 if function_arguments > 0 else 0

                    if inside_import_block == True: inside_import_block = False
                # anons
                case '{' | '}' | '[' | ']':
                    tokens.append(Token(TokenType._ANON, current_char_index, current_char))
                    current_char_index += 1
                case ',' | ';' | ':' | '@' | '\\' | '´' | '`':
                    tokens.append(Token(TokenType._ANON, current_char_index, current_char))
                    current_char_index += 1
                    # update state for custom function declaration styling
                    if function_declaration and function_parameters == 0:
                        function_declaration = False
                        skip_next_parameter = False
                    # only highlight keys at lowest level as parameters
                    if function_declaration and function_parameters == 1 and skip_next_parameter and current_char == ",": skip_next_parameter = False
                case '=':
                    # conditional
                    next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                    if next_char == '=':
                        tokens.append(Token(TokenType.CONDITIONAL, current_char_index, "=="))
                        current_char_index += 2
                    # operator
                    else:
                        tokens.append(Token(TokenType.OPERATOR, current_char_index, current_char))
                        current_char_index += 1
                        # todo : set custom styling for identifiers before = as parameters
                        if function_arguments == 1: tokens[-2].type = TokenType.PARAMETER
                case '!':
                    # conditional
                    next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                    if next_char == '=':
                        tokens.append(Token(TokenType.CONDITIONAL, current_char_index, "!="))
                        current_char_index += 2
                    else:
                        # raise Exception("tokenize : unknown character :", current_char + next_char)
                        tokens.append(Token(TokenType.OPERATOR, current_char_index, current_char))
                        current_char_index += 1
                case '<':
                    next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                    if next_char == '=':
                        tokens.append(Token(TokenType.CONDITIONAL, current_char_index, "<="))
                        current_char_index += 2
                    elif next_char == '<':
                        tokens.append(Token(TokenType.CONDITIONAL, current_char_index, "<<"))
                        current_char_index += 2
                    else:
                        tokens.append(Token(TokenType.CONDITIONAL, current_char_index, current_char))
                        current_char_index += 1
                case '>':
                    next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                    if next_char == '=':
                        tokens.append(Token(TokenType.CONDITIONAL, current_char_index, ">="))
                        current_char_index += 2
                    elif next_char == '>':
                        tokens.append(Token(TokenType.CONDITIONAL, current_char_index, ">>"))
                        current_char_index += 2
                    else:
                        tokens.append(Token(TokenType.CONDITIONAL, current_char_index, current_char))
                        current_char_index += 1
                # strings
                case '"' | '\'':
                    start_pos = current_char_index
                    string = str(current_char)

                    # update state for custom format string styling
                    format_string = False
                    if len(tokens) > 0 and tokens[-1].type == TokenType.IDENTIFIER and tokens[-1].value == "f":
                        tokens[-1].type = TokenType.BUILT_IN
                        format_string = True
                    
                    # multi-line (triple)                
                    next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                    next_next_char = text[current_char_index + 2] if current_char_index + 2 < len(text) else None
                    if next_char == current_char and next_next_char == current_char:
                        string += str(current_char*2)
                        current_char_index += 3

                        # while current_char_index < len(text) and (text[current_char_index].isprintable() or text[current_char_index] == '\n'):
                        while current_char_index < len(text):
                            string += str(text[current_char_index])
                            
                            next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else None
                            next_next_char = text[current_char_index + 2] if current_char_index + 2 < len(text) else None
                            if text[current_char_index] == current_char and next_char == current_char and next_next_char == current_char:
                                string += str(current_char*2)
                                current_char_index += 3
                                break
                            else:
                                current_char_index += 1
                    else:
                        current_char_index += 1

                        # while current_char_index < len(text) and text[current_char_index].isprintable():
                        while current_char_index < len(text):
                            string += str(text[current_char_index])
                            if text[current_char_index] == current_char:
                                current_char_index += 1
                                break
                            else:
                                current_char_index += 1

                    # use regex to match f-string
                    if format_string:
                        fstring_pattern = re.compile(f"({self.FSTRING_REGEX['STRING_TEXT']})|({self.FSTRING_REGEX['EXPRESSION']})|({self.FSTRING_REGEX['ESCAPE_SEQ']})")
                        for match in fstring_pattern.finditer(string):
                            f_start_pos = match.start()
                            f_end_pos = match.end()
                            
                            # match regular text
                            if match.group(1):
                                tokens.append(Token(TokenType.STRING, start_pos + f_start_pos, match.group(1)))
                            
                            # match format string expressions
                            elif match.group(2):
                                f_tokens, _, _ = self.tokenize(match.group(2))
                                for token in f_tokens:
                                    new_pos = start_pos + f_start_pos + token.start_pos
                                    tokens.append(Token(token.type, new_pos, token.value))
                            
                            # match escaped characters
                            elif match.group(3):
                                tokens.append(Token(TokenType.SPECIAL, start_pos + f_start_pos, match.group(3)))
                    else:
                        tokens.append(Token(TokenType.STRING, start_pos, string))

                case _:
                    # number
                    if current_char.isdigit():
                        start_pos = current_char_index
                        number = str(current_char)
                        current_char_index += 1
                        
                        while current_char_index < len(text) and (text[current_char_index].isdigit() or text[current_char_index].isalpha() or text[current_char_index] in ["."]):
                            number += str(text[current_char_index])
                            current_char_index += 1

                        # match using regex
                        number_type = TokenType.DEFAULT
                        for type_, pattern in self.NUMBER_REGEX.items():
                            if re.match(pattern, number):
                                number_type = TokenType.NUMBER
                                break

                        if number_type == TokenType.NUMBER:
                            tokens.append(Token(TokenType.NUMBER, start_pos, number))
                        else:
                            tokens.append(Token(TokenType.DEFAULT, start_pos, number))

                    # identifiers
                    elif current_char.isidentifier():
                        start_pos = current_char_index
                        identifier = str(current_char)
                        current_char_index += 1
                        
                        while current_char_index < len(text) and (text[current_char_index].isidentifier() or text[current_char_index].isdigit()):
                            identifier += str(text[current_char_index])
                            current_char_index += 1

                        # use default inside imports
                        if inside_import == True:
                            tokens.append(Token(TokenType.DEFAULT, start_pos, identifier))
                        # conditional
                        elif identifier in self.CONSTANTS:
                            tokens.append(Token(TokenType.CONDITIONAL, start_pos, identifier))
                        # special
                        elif identifier in self.SPECIALS and not (function_declaration and identifier == "self"):
                            # if identifier == "self":
                            #     tokens.append(Token(TokenType.SPECIALC, start_pos, identifier))
                            # else:
                            #     tokens.append(Token(TokenType.SPECIAL, start_pos, identifier))
                            tokens.append(Token(TokenType.SPECIAL, start_pos, identifier))
                        # built_in
                        elif identifier in self.BUILT_INS:
                            tokens.append(Token(TokenType.BUILT_IN, start_pos, identifier))
                        # parameter : todo : rename this to avoid confusion
                        elif identifier in self.FUNC_PARAMS:
                            tokens.append(Token(TokenType.PARAMETER, start_pos, identifier))
                        # keyword
                        elif identifier in self.KEYWORDS:
                            tokens.append(Token(TokenType.KEYWORD, start_pos, identifier))
                            # update state for custom function declaration styling
                            if identifier in { "def" }: function_declaration = True
                            if identifier in { "import" }: inside_import = True
                        # single underscore is special
                        elif identifier == "_":
                            tokens.append(Token(TokenType.SPECIAL, start_pos, identifier))
                        # identifier
                        else:
                            n = 0
                            next_non_empty_char = text[current_char_index] if current_char_index < len(text) else None
                            while next_non_empty_char != None and next_non_empty_char.strip() == "" and current_char_index + n < len(text):
                                n += 1
                                next_non_empty_char = text[current_char_index + n] if current_char_index + n < len(text) else None
                            
                            # custom style for function and class name
                            if function_declaration and function_parameters == 0:
                                tokens.append(Token(TokenType.NAME, start_pos, identifier))
                                # append name to FUNCTION_DIR
                                if identifier not in self.FUNCTION_DIR: self.FUNCTION_DIR.append(identifier)
                            
                            # custom style for function parameters
                            elif function_declaration and function_parameters == 1 and not skip_next_parameter:
                                # print(next_non_empty_char)

                                if next_non_empty_char in { ":" }: skip_next_parameter = True
                                # if next_non_empty_char in { ",", ")" }: skip_next_parameter = False
                                
                                tokens.append(Token(TokenType.PARAMETER, start_pos, identifier))
                            
                            # otherwise
                            else:
                                if len(tokens) > 0 and tokens[-1].type == TokenType.KEYWORD and tokens[-1].value == "class":
                                    tokens.append(Token(TokenType.CLASS, start_pos, identifier))
                                    # append to CLASS_DIR
                                    if identifier not in self.CLASS_DIR: self.CLASS_DIR.append(identifier)
                                else:
                                    if identifier in self.CLASS_DIR:
                                        tokens.append(Token(TokenType.CLASS, start_pos, identifier))
                                    elif identifier in self.FUNCTION_DIR:
                                        tokens.append(Token(TokenType.NAME, start_pos, identifier))
                                    else:
                                        # using identifier as type to easier find and style identifiers post lexing
                                        tokens.append(Token(TokenType.IDENTIFIER, start_pos, identifier))
                    else:
                        # raise Exception("tokenize : unknown character :", current_char)
                        tokens.append(Token(TokenType.DEFAULT, current_char_index, current_char))
                        current_char_index += 1

        # todo : probably easier to just return declaration string (and match def NAME for navigation to declaration in editor?)
        return tokens, self.CLASS_DIR, self.FUNCTION_DIR
