
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

// 0  WHITESPACE
// 1  DEFAULT
// 2  KEYWORD
// 3  CLASS
// 4  NAME
// 5  PARAMETER
// 6  LAMBDA
// 7  STRING
// 8  NUMBER
// 9  OPERATOR
// 10 COMMENT
// 11 SPECIAL
// 12 CONDITIONAL
// 13 BUILT_IN
// 14 ERROR
// 15 WARNING
// 16 SUCCESS

package odin_odin

import "base:runtime"
import "core:strings"
import "core:fmt"

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

@export tokenize :: proc(text: string) -> [dynamic]Token {
    alloc := runtime.default_allocator() // need to do this to not get assertion erron when calling from FFI

    tokens: [dynamic]Token
    tokens = runtime.make([dynamic]Token, 0, alloc);
    
    index: int = 0
    for index < len(text) {
        if text[index] == ' ' || text[index] == '\t' || text[index] == '\n' {
            index += 1
            continue
        }

        // comment | operator
        if text[index] == '/' {
            fmt.println("matched /")
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)

            strings.write_byte(&lexeme, text[index]) // add '/' to lexeme buffer
            
            // single-line comment
            if index + 1 < len(text) && text[index + 1] == '/' {
                fmt.println("matched //")
                
                start_pos := index
                strings.write_byte(&lexeme, text[index + 1]) // add '/' to lexeme buffer
                index += 2
                for index < len(text) && text[index] != '\n' {
                    strings.write_byte(&lexeme, text[index])
                    index += 1
                }
                append(&tokens, Token{ type = 10, start_pos = start_pos, value = strings.to_string(lexeme) })
                continue
            }
            
            // multi-line comment
            if index + 1 < len(text) && text[index + 1] == '*' {
                fmt.println("matched /*")
                
                start_pos := index
                strings.write_byte(&lexeme, text[index + 1]) // add '*' to lexeme buffer
                index += 2
                for index < len(text) && index + 1 < len(text) && text[index] != '*' && text[index + 1] != '/' {
                    strings.write_byte(&lexeme, text[index])
                    index += 1
                }
                // fmt.println(strings.to_string(text[index]))
                // fmt.println(strings.to_string(text[index + 1]))

                // check if multi-line comment is closed
                if index < len(text) && index + 1 < len(text) && text[index] == '*' && text[index + 1] == '/' {
                    strings.write_byte(&lexeme, text[index]) // add '*' to lexeme buffer
                    strings.write_byte(&lexeme, text[index + 1])  // add '/' to lexeme buffer
                    index += 2

                    fmt.println(strings.to_string(lexeme))
                    append(&tokens, Token{ type = 10, start_pos = start_pos, value = strings.to_string(lexeme) })
                
                // otherwise return default
                } else {
                    fmt.println(strings.to_string(lexeme))
                    append(&tokens, Token{ type = 1, start_pos = start_pos, value = strings.to_string(lexeme) })
                }

                continue
            }
            
            fmt.println("OK")
            
            // operator
            append(&tokens, Token{ type = 9, start_pos = index, value = strings.to_string(lexeme) })
            index += 1
            continue
        }

        // :: or :
        if text[index] == ':' {
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)

            strings.write_byte(&lexeme, text[index]) // add ':' to lexeme buffer

            // constant?
            if index + 1 < len(text) && text[index + 1] == ':' {
                start_pos := index
                strings.write_byte(&lexeme, text[index + 1]) // add ':' to lexeme buffer
                index += 2
                append(&tokens, Token{ type = 2, start_pos = start_pos, value = strings.to_string(lexeme) })
            // range
            } else {
                append(&tokens, Token{ type = 9, start_pos = index, value = strings.to_string(lexeme) })
                index += 1
            }
            continue
        }

        // .. or .
        if text[index] == '.'  {
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            strings.write_byte(&lexeme, text[index]) // add '.' to lexeme buffer
            
            // range
            if index + 1 < len(text) && text[index + 1] == '.' {
                start_pos := index
                strings.write_byte(&lexeme, text[index + 1]) // add '.' to lexeme buffer
                index += 2
                append(&tokens, Token{ type = 9, start_pos = start_pos, value = strings.to_string(lexeme) })
            // anon
            } else {
                append(&tokens, Token{ type = 1, start_pos = index, value = strings.to_string(lexeme) })
                index += 1
            }
            continue
        }

        // operator
        if text[index] == '=' || text[index] == '!' || text[index] == '^' || text[index] == '?' || text[index] == '+' || text[index] == '-' ||
           text[index] == '*' || text[index] == '/' || text[index] == '%' || text[index] == '&' || text[index] == '|' || text[index] == '~' ||
           text[index] == '|' || text[index] == '<' || text[index] == '>' {
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            strings.write_byte(&lexeme, text[index])
            append(&tokens, Token{ type = 9, start_pos = index, value = strings.to_string(lexeme) })
            index += 1
            continue
        }

        // directive
        if text[index] == '#'  {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            strings.write_byte(&lexeme, text[index]) // add '#' to lexeme buffer
            index += 1
            
            // directive
            for index < len(text) && ((text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' || (text[index] >= '0' && text[index] <= '9')) {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }
            append(&tokens, Token{ type = 2, start_pos = start_pos, value = strings.to_string(lexeme) })
            continue
        }

        // string
        // todo : add '' and ``
        if text[index] == '"' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            strings.write_byte(&lexeme, text[index]) // add '"' to lexeme buffer
            index += 1
            for index < len(text) && text[index] != '"' {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }
            
            strings.write_byte(&lexeme, text[index]) // add '"' to lexeme buffer
            index += 1
            
            append(&tokens, Token{ type = 7, start_pos = start_pos, value = strings.to_string(lexeme) })
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
            append(&tokens, Token{ type = 8, start_pos = start_pos, value = strings.to_string(lexeme) })
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
                append(&tokens, Token{ type = 12, start_pos = start_pos, value = strings.to_string(lexeme) })
            // keyword
            } else if is_keyword(strings.to_string(lexeme)) {
                append(&tokens, Token{ type = 2, start_pos = start_pos, value = strings.to_string(lexeme) })
            // built_in
            } else if is_built_in(strings.to_string(lexeme)) {
                append(&tokens, Token{ type = 13, start_pos = start_pos, value = strings.to_string(lexeme) })
            // type
            } else if is_type(strings.to_string(lexeme)) {
                append(&tokens, Token{ type = 11, start_pos = start_pos, value = strings.to_string(lexeme) })
            // default
            } else {
                append(&tokens, Token{ type = 1, start_pos = start_pos, value = strings.to_string(lexeme) })
            }
            continue
        }

        lexeme := strings.builder_make(alloc) // helper to store lexemes
        // defer strings.builder_destroy(&lexeme)
        
        strings.write_byte(&lexeme, text[index])
        append(&tokens, Token{ type = 1, start_pos = index, value = strings.to_string(lexeme) })
        index += 1
    }

    return tokens
}

// odin run odin_odin
// odin build odin_odin -build-mode:dll

@export process_input :: proc(arg: string) -> [dynamic]Token {    
    result := tokenize(arg)
    // fmt.println(result)

    return result
}

// main :: proc() {
//     TEXT :: `
//     @(cold)
//     `

//     result := tokenize(TEXT)
//     fmt.println(result)
// }

