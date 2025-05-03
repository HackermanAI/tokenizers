
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

// Tokenizer for Odin
// Generate dylib -> odin build odin.odin -file -build-mode:dll

package odin_tokenizer

import "base:runtime"
import "core:strings"
import "core:fmt"

import "core:unicode/utf8"

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
TYPE        :: 17

KEYWORDS: [35]string = [35]string{
    "asm",
    "auto_cast",
    "bit_set",
    "break",
    "case",
    "cast",
    "context",
    "continue",
    "defer",
    "distinct",
    "do",
    "dynamic",
    "else",
    "enum",
    "fallthrough",
    "for",
    "foreign",
    "if",
    "import",
    "in",
    "map",
    "not_in",
    "or_else",
    "or_return",
    "package",
    "proc",
    "return",
    "struct",
    "switch",
    "transmute",
    "typeid",
    "union",
    "using",
    "when",
    "where",
}

BUILT_INS: [3]string = [3]string{
    "fmt",
    "len",
    "println",
}

TYPES: [21]string = [21]string{
    "i8",
    "i16",
    "i32",
    "i64",
    "i128",
    "int",
    "u8",
    "u16",
    "u32",
    "u64",
    "u128",
    "uint",
    "f32",
    "f64",
    "complex64",
    "complex128",
    "quaternion128",
    "quaternion256",
    "string",
    "rune",
    "bool",
}

is_keyword :: proc(value: string) -> bool {
    for keyword in KEYWORDS {
        if keyword == value {
            return true
        }
    }
    return false
}

is_built_in :: proc(value: string) -> bool {
    for built_in in BUILT_INS {
        if built_in == value {
            return true
        }
    }
    return false
}

is_type :: proc(value: string) -> bool {
    for type in TYPES {
        if type == value {
            return true
        }
    }
    return false
}

is_conditional :: proc(value: string) -> bool {
    return value == "true" || value == "false"
}

Token :: struct {
    type: int,
    start_pos: int,
    value: string,
}

convert_to_runes :: proc(text: string) -> [dynamic]rune {
    alloc := runtime.default_allocator()
    runes: [dynamic]rune = runtime.make([dynamic]rune, 0, alloc)
    
    i: int = 0
    for i < len(text) {
        r, width := utf8.decode_rune(text[i:])
        append_elem(&runes, r)
        i += width
    }
    return runes
}

@(optimization_mode="favor_size")
tokenize :: proc(text: string) -> [dynamic]Token {    
    alloc := runtime.default_allocator() // need to do this to not get assertion error when calling from FFI
    tokens: [dynamic]Token = runtime.make([dynamic]Token, 0, alloc);

    // todo : return pointer to token array to use in call back to free memory

    runes := convert_to_runes(text)
    
    index: int = 0
    for index < len(runes) {

        // whitespace
        if runes[index] == ' ' || runes[index] == '\t' || runes[index] == '\n' {
            index += 1
            continue
        }

        // attribute
        if runes[index] == '@' {
            lexeme := strings.builder_make(alloc)
            strings.write_rune(&lexeme, runes[index])
            
            append(&tokens, Token{ type = OPERATOR, start_pos = index, value = strings.to_string(lexeme) })
            index += 1

            continue
        }

        // comment | operator
        if runes[index] == '/' {
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)

            strings.write_rune(&lexeme, runes[index]) // add '/' to lexeme buffer
            
            // single-line comment
            if index + 1 < len(runes) && runes[index + 1] == '/' {
                start_pos := index
                strings.write_rune(&lexeme, runes[index + 1]) // add '/' to lexeme buffer
                index += 2
                
                for index < len(runes) && runes[index] != '\n' {
                    strings.write_rune(&lexeme, runes[index])
                    index += 1
                }
                
                append(&tokens, Token{ type = COMMENT, start_pos = start_pos, value = strings.to_string(lexeme) })
                
                continue
            }
            
            // multi-line comment
            if index + 1 < len(runes) && runes[index + 1] == '*' {
                start_pos := index
                strings.write_rune(&lexeme, runes[index + 1]) // add '*' to lexeme buffer
                index += 2
                
                for index < len(runes) && index + 1 < len(runes) && runes[index] != '*' && runes[index + 1] != '/' {
                    strings.write_rune(&lexeme, runes[index])
                    index += 1
                }

                // check if multi-line comment is closed
                if index < len(runes) && index + 1 < len(runes) && runes[index] == '*' && runes[index + 1] == '/' {
                    strings.write_rune(&lexeme, runes[index]) // add '*' to lexeme buffer
                    strings.write_rune(&lexeme, runes[index + 1])  // add '/' to lexeme buffer
                    index += 2

                    append(&tokens, Token{ type = COMMENT, start_pos = start_pos, value = strings.to_string(lexeme) })
                
                // otherwise return default
                } else {
                    append(&tokens, Token{ type = ERROR, start_pos = start_pos, value = strings.to_string(lexeme) })
                }

                continue
            }
            
            // operator
            append(&tokens, Token{ type = OPERATOR, start_pos = index, value = strings.to_string(lexeme) })
            index += 1
            
            continue
        }

        // :: or :
        if runes[index] == ':' {
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)

            strings.write_rune(&lexeme, runes[index]) // add ':' to lexeme buffer

            // constant
            if index + 1 < len(runes) && runes[index + 1] == ':' {
                start_pos := index
                strings.write_rune(&lexeme, runes[index + 1]) // add ':' to lexeme buffer
                index += 2
                
                append(&tokens, Token{ type = KEYWORD, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            // range
            } else {
                append(&tokens, Token{ type = OPERATOR, start_pos = index, value = strings.to_string(lexeme) })
                index += 1
            }
            
            continue
        }

        // .. or .
        if runes[index] == '.'  {
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            strings.write_rune(&lexeme, runes[index]) // add '.' to lexeme buffer
            
            // range
            if index + 1 < len(runes) && runes[index + 1] == '.' {
                start_pos := index
                strings.write_rune(&lexeme, runes[index + 1]) // add '.' to lexeme buffer
                index += 2
                
                append(&tokens, Token{ type = OPERATOR, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            // default
            } else {
                append(&tokens, Token{ type = DEFAULT, start_pos = index, value = strings.to_string(lexeme) })
                index += 1
            }
            
            continue
        }

        // operator
        if runes[index] == '=' || runes[index] == '!' || runes[index] == '^' || runes[index] == '?' || runes[index] == '+' || runes[index] == '-' ||
           runes[index] == '*' || runes[index] == '/' || runes[index] == '%' || runes[index] == '&' || runes[index] == '|' || runes[index] == '~' ||
           runes[index] == '|' || runes[index] == '<' || runes[index] == '>' {

            lexeme := strings.builder_make(alloc)
            strings.write_rune(&lexeme, runes[index])
            
            append(&tokens, Token{ type = OPERATOR, start_pos = index, value = strings.to_string(lexeme) })
            index += 1
            
            continue
        }

        // directive
        if runes[index] == '#'  {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            strings.write_rune(&lexeme, runes[index]) // add '#' to lexeme buffer
            index += 1
            
            // directive
            for index < len(runes) && ((runes[index] >= 'a' && runes[index] <= 'z') || (runes[index] >= 'A' && runes[index] <= 'Z') || runes[index] == '_' || (runes[index] >= '0' && runes[index] <= '9')) {
                strings.write_rune(&lexeme, runes[index])
                index += 1
            }
            
            append(&tokens, Token{ type = KEYWORD, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            continue
        }

        // string
        if runes[index] == '"' || runes[index] == '\'' || runes[index] == '`' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)

            quote := runes[index]
            
            strings.write_rune(&lexeme, runes[index]) // add open quote to lexeme buffer
            index += 1
            for index < len(runes) && runes[index] != quote {
                strings.write_rune(&lexeme, runes[index])
                index += 1
            }
            if index < len(runes) {
                strings.write_rune(&lexeme, runes[index]) // add closing quote to lexeme buffer (if any)
                index += 1

                append(&tokens, Token{ type = STRING, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            // no closing quote
            } else {
                append(&tokens, Token{ type = ERROR, start_pos = start_pos, value = strings.to_string(lexeme) })
            }
            
            continue
        }

        // number
        if runes[index] >= '0' && runes[index] <= '9' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            for index < len(runes) && ((runes[index] >= '0' && runes[index] <= '9') || runes[index] == '.') {
                strings.write_rune(&lexeme, runes[index])
                index += 1
            }
            
            append(&tokens, Token{ type = NUMBER, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            continue
        }

        // conditional | keyword | built_in | type | _
        if (runes[index] >= 'a' && runes[index] <= 'z') || (runes[index] >= 'A' && runes[index] <= 'Z') || runes[index] == '_' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            for index < len(runes) && ((runes[index] >= 'a' && runes[index] <= 'z') || (runes[index] >= 'A' && runes[index] <= 'Z') || runes[index] == '_' || (runes[index] >= '0' && runes[index] <= '9')) {
                strings.write_rune(&lexeme, runes[index])
                index += 1
            }

            // conditional
            if is_conditional(strings.to_string(lexeme)) {
                append(&tokens, Token{ type = CONDITIONAL, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            // keyword
            } else if is_keyword(strings.to_string(lexeme)) {
                append(&tokens, Token{ type = KEYWORD, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            // built_in
            } else if is_built_in(strings.to_string(lexeme)) {
                append(&tokens, Token{ type = BUILT_IN, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            // types
            } else if is_type(strings.to_string(lexeme)) {
                append(&tokens, Token{ type = TYPE, start_pos = start_pos, value = strings.to_string(lexeme) })
            
            // name
            } else {
                append(&tokens, Token{ type = NAME, start_pos = start_pos, value = strings.to_string(lexeme) })
            }
            
            continue
        }

        lexeme := strings.builder_make(alloc)
        strings.write_rune(&lexeme, runes[index])

        append(&tokens, Token{ type = DEFAULT, start_pos = index, value = strings.to_string(lexeme) })
        index += 1
    }

    return tokens
}

@export process_input :: proc(arg: string) -> [dynamic]Token {
    result := tokenize(arg)
    return result
}

// for testing only
// main :: proc() {
//     TEXT :: `
//     @(cold)
//     `

//     result := tokenize(TEXT)
//     fmt.println(result)
// }

