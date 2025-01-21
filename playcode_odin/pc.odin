
// MIT License

// Copyright 2025 @asyncze (Michael Sjöberg)

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Tokenizer for PlayCode
// https://github.com/asyncze/playcode

package playcode_odin

import "base:runtime"
import "core:strings"
import "core:fmt"

WHITESPACE  :: 0
DEFAULT     :: 1
KEYWORD     :: 2
CLASS       :: 3
NAME        :: 4
PARAMETER   :: 5
LAMBDA      :: 6
STRING      :: 7
NUMBER      :: 8
OPERATOR    :: 9
COMMENT     :: 10
SPECIAL     :: 11
CONDITIONAL :: 12
BUILT_IN    :: 13
ERROR       :: 14
WARNING     :: 15
SUCCESS     :: 16

KEYWORDS: [5]string = [5]string{
    "if",
    "else",
    "while",
    "swap",
    "print"
}

is_keyword :: proc(value: string) -> bool {
    for keyword in KEYWORDS {
        if keyword == value {
            return true
        }
    }
    return false
}

is_conditional :: proc(value: string) -> bool {
    return value == "True" || value == "False"
}

Token :: struct {
    type: int,
    start_pos: int,
    value: string,
}

tokenize :: proc(text: string) -> [dynamic]Token {
    alloc := runtime.default_allocator() // need to do this to not get assertion erron when calling from FFI

    tokens: [dynamic]Token
    tokens = runtime.make([dynamic]Token, 0, alloc);
    
    index: int = 0
    for index < len(text) {
        if text[index] == ' ' || text[index] == '\t' || text[index] == '\n' {
            index += 1
            continue
        }

        // comment | assert | operator
        if text[index] == '-' {
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)

            strings.write_byte(&lexeme, text[index]) // add '-' to lexeme buffer

            // comment
            if index + 1 < len(text) && text[index + 1] == '-' {
                start_pos := index
                strings.write_byte(&lexeme, text[index + 1]) // add '-' to lexeme buffer
                index += 2
                for index < len(text) && text[index] != '\n' {
                    strings.write_byte(&lexeme, text[index])
                    index += 1
                }
                
                append(&tokens, Token{ type = COMMENT, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            // assert
            } else if index + 1 < len(text) && text[index + 1] == '>' {
                start_pos := index
                strings.write_byte(&lexeme, text[index + 1]) // add '>' to lexeme buffer
                index += 2
                
                append(&tokens, Token{ type = SPECIAL, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            // operator
            } else {
                append(&tokens, Token{ type = OPERATOR, start_pos = index, value = strings.to_string(lexeme) })
                index += 1
            }
            continue
        }

        // operator
        if text[index] == '=' || text[index] == '!' || text[index] == '+' || text[index] == '-' ||
           text[index] == '*' || text[index] == '/' || text[index] == '<' || text[index] == '>' {
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            strings.write_byte(&lexeme, text[index])
            append(&tokens, Token{ type = OPERATOR, start_pos = index, value = strings.to_string(lexeme) })
            index += 1
            continue
        }

        // tag
        if text[index] == '@'  {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            strings.write_byte(&lexeme, text[index]) // add '@' to lexeme buffer
            index += 1
            
            for index < len(text) && ((text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_') {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }
            append(&tokens, Token{ type = LAMBDA, start_pos = start_pos, value = strings.to_string(lexeme) })
            continue
        }

        // string
        if text[index] == '"' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)

            quote := text[index]
            
            strings.write_byte(&lexeme, text[index]) // add open quote to lexeme buffer
            index += 1
            for index < len(text) && text[index] != quote {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }
            if index < len(text) {
                strings.write_byte(&lexeme, text[index]) // add closing quote to lexeme buffer (if any)
                index += 1
            }
            
            append(&tokens, Token{ type = STRING, start_pos = start_pos, value = strings.to_string(lexeme) })
            continue
        }

        // number
        if text[index] >= '0' && text[index] <= '9' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            for index < len(text) && ((text[index] >= '0' && text[index] <= '9') || text[index] == '.') {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }
            append(&tokens, Token{ type = NUMBER, start_pos = start_pos, value = strings.to_string(lexeme) })
            continue
        }

        // conditional | keyword | built_in | type | _
        if (text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            for index < len(text) && ((text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' || (text[index] >= '0' && text[index] <= '9')) {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }

            // conditional
            if is_conditional(strings.to_string(lexeme)) {
                append(&tokens, Token{ type = CONDITIONAL, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            // keyword
            } else if is_keyword(strings.to_string(lexeme)) {
                // replace token at -2 with name if proc declaration (otherwise default)
                if strings.to_string(lexeme) == "proc" {
                    assign_at(&tokens, len(tokens) - 2, Token{ type = NAME, start_pos = tokens[len(tokens) - 2].start_pos, value = tokens[len(tokens) - 2].value })
                }

                append(&tokens, Token{ type = KEYWORD, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            // default
            } else {
                append(&tokens, Token{ type = DEFAULT, start_pos = start_pos, value = strings.to_string(lexeme) })
            }
            continue
        }

        lexeme := strings.builder_make(alloc) // helper to store lexemes
        // defer strings.builder_destroy(&lexeme)
        
        strings.write_byte(&lexeme, text[index])
        append(&tokens, Token{ type = DEFAULT, start_pos = index, value = strings.to_string(lexeme) })
        index += 1
    }

    return tokens
}

// odin run playcode_odin
// odin build playcode_odin -build-mode:dll

@export process_input :: proc(arg: string) -> [dynamic]Token {
    result := tokenize(arg)
    return result
}
