
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
                
                # whitespace
                case ' ' | '\t' | '\r':
                    current_char_index += 1

                # newline
                case '\n':
                    current_char_index += 1
                    
                    RHS = False # reset state

                # comment
                case '#':
                    start_pos = current_char_index
                    current_char_index += 1
                    
                    line = current_char
                    
                    while current_char_index < len(text) and text[current_char_index] != '\n':
                        line += text[current_char_index]
                        current_char_index += 1
                    
                    tokens.append((COMMENT, start_pos, line))

                # assignment
                case '=':
                    tokens.append((BUILT_IN, current_char_index, current_char))
                    current_char_index += 1
                    
                    RHS = True # update state
                
                # header or list
                case '[':
                    start_pos = current_char_index
                    current_char_index += 1

                    header = str(current_char)

                    # nested headers
                    if not RHS:
                        nested_level = 0
                        while current_char_index < len(text) and text[current_char_index].isprintable():
                            header += str(text[current_char_index])
                            
                            # increase nested level
                            if text[current_char_index] == '[':
                                nested_level += 1
                                current_char_index += 1
                            
                            # decrease nested level (until no)
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
                
                # anon
                case ']' | '{' | '}' | ',' | '.':
                    tokens.append((DEFAULT, current_char_index, current_char))
                    current_char_index += 1
                
                # string
                case '"' | '\'':
                    start_pos = current_char_index                    
                    current_char_index += 1

                    string = str(current_char)

                    while current_char_index < len(text) and text[current_char_index].isprintable():
                        string += str(text[current_char_index])
                        
                        # exit on current_char == " or current_char == ' (whatever opened string)
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
                        current_char_index += 1

                        number = str(current_char)
                        
                        while current_char_index < len(text) and (
                            text[current_char_index].isdigit() or
                            text[current_char_index].isalpha() or
                            text[current_char_index] in [".", "+", "-", "_"]
                        ):
                            number += str(text[current_char_index])
                            current_char_index += 1

                        tokens.append((NUMBER, start_pos, number))
                    
                    # identifiers
                    elif current_char.isidentifier():
                        start_pos = current_char_index
                        current_char_index += 1

                        identifier = str(current_char)
                        
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
                    
                    # catch-all
                    else:
                        tokens.append((DEFAULT, current_char_index, current_char))
                        current_char_index += 1

        return tokens
