
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

# Tokenizer for TOML

WHITESPACE  = "whitespace"
DEFAULT     = "default"
KEYWORD     = "keyword"
CLASS       = "class"
NAME        = "name"
PARAMETER   = "PARAMETER"
LAMBDA      = "lambda"
STRING      = "string"
NUMBER      = "number"
OPERATOR    = "operator"
COMMENT     = "comment"
SPECIAL     = "special"
CONDITIONAL = "conditional"
BUILT_IN    = "built_in"
ERROR       = "error"
WARNING     = "warning"
SUCCESS     = "success"

class Lexer(object):
    def __init__(self): pass

    def comment_char(self): return "#"

    def lexer_name(self): return "TOML"

    def tokenize(self, text):
        tokens = []
        current_char = ''
        current_char_index = 0

        RHS = False # helper to detect non-header brackets

        while current_char_index < len(text):
            current_char = text[current_char_index]
            match current_char:
                case ' ' | '\t' | '\r':
                    current_char_index += 1
                case '\n':
                    current_char_index += 1
                    # update state
                    RHS = False
                case '#':
                    start_pos = current_char_index
                    current_char_index += 1
                    line = current_char
                    while current_char_index < len(text) and text[current_char_index] != '\n':
                        line += text[current_char_index]
                        current_char_index += 1
                    tokens.append((COMMENT, start_pos, line))
                case '=':
                    tokens.append((BUILT_IN, current_char_index, current_char))
                    current_char_index += 1
                    # update state
                    RHS = True
                case '[':
                    start_pos = current_char_index
                    header = str(current_char)
                    
                    current_char_index += 1

                    if RHS == False:
                        nested_level = 0
                        while current_char_index < len(text) and text[current_char_index].isprintable():
                            header += str(text[current_char_index])
                            if text[current_char_index] == '[':
                                nested_level += 1
                                current_char_index += 1
                            elif text[current_char_index] == ']':
                                current_char_index += 1
                                if nested_level > 0:
                                    nested_level -= 1
                                else:
                                    break
                            else:
                                current_char_index += 1

                        tokens.append((KEYWORD, start_pos, header))
                    else:
                        tokens.append((DEFAULT, start_pos, current_char))    
                
                # anons
                case ']' | '{' | '}' | ',' | '.':
                    tokens.append((DEFAULT, current_char_index, current_char))
                    current_char_index += 1
                
                # strings
                case '"' | '\'':
                    start_pos = current_char_index
                    string = str(current_char)
                    
                    current_char_index += 1

                    while current_char_index < len(text) and text[current_char_index].isprintable():
                        string += str(text[current_char_index])
                        if text[current_char_index] == current_char:
                            current_char_index += 1
                            break
                        else:
                            current_char_index += 1
                    
                    tokens.append((STRING, start_pos, string))
                case _:
                    
                    # number
                    if current_char.isdigit() or current_char in { "+", "-" }:
                        start_pos = current_char_index
                        number = str(current_char)
                        current_char_index += 1
                        
                        while current_char_index < len(text) and (text[current_char_index].isdigit() or text[current_char_index].isalpha() or text[current_char_index] in [".", "+", "-", "_"]):
                            number += str(text[current_char_index])
                            current_char_index += 1

                        # match using regex
                        # number_type = DEFAULT
                        # for type_, pattern in self.TOML_NUMBER_PATTERNS.items():
                        #     if re.match(pattern, number):
                        #         number_type = NUMBER
                        #         break

                        # if number_type == NUMBER:
                        #     tokens.append((NUMBER, start_pos, number))
                        # else:
                        #     tokens.append((DEFAULT, start_pos, number))
                        tokens.append((NUMBER, start_pos, number))
                    
                    # identifiers
                    elif current_char.isidentifier():
                        start_pos = current_char_index
                        identifier = str(current_char)
                        current_char_index += 1
                        
                        while current_char_index < len(text) and text[current_char_index].isidentifier():
                            identifier += str(text[current_char_index])
                            current_char_index += 1

                        # conditional
                        if identifier in { "true", "false" }:
                            tokens.append((CONDITIONAL, start_pos, identifier))
                        # nan
                        elif identifier in { "nan", "inf" }:
                            tokens.append((NUMBER, start_pos, identifier))
                        # identifier
                        else:   
                            tokens.append((DEFAULT, start_pos, identifier))
                    else:
                        tokens.append((DEFAULT, current_char_index, current_char))
                        current_char_index += 1

        return tokens
