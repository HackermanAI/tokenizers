
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

// Tokenizer for Hackerman DSCL (TOML-like custom DSL)

package test

import "base:runtime"

import "core:os"
import "core:fmt"
import "core:mem"
import "core:strings"
import "core:strconv"

NAME: [23]string = [23]string{
    "font", "font_weight", "font_size", "tab_width", "cursor_width",
    "margin", "theme", "file_explorer_root", "model_to_use", "eol_mode",
    "show_line_numbers", "transparent", "blockcursor", "wrap_word",
    "blinking_cursor", "show_scrollbar", "show_minimap", "highlight_todos",
    "whitespace_visible", "indent_guides", "highlight_current_line",
    "highlight_current_line_on_jump", "show_eol",
}

NAME_COUNT := len(NAME)

is_name :: proc(value: string) -> bool {
    for name in NAME {
        if name == value {
            return true
        }
    }
    return false
}

is_conditional :: proc(value: string) -> bool {
    return value == "true" || value == "false"
}

@export free_memory :: proc () {
    free_all(context.temp_allocator)
    fmt.println("free_memory", "finished")
}

@export tokenize :: proc(text: string) -> string {
    fmt.println("Odin : tokenize called :", text)
    
    // result := strings.builder_make(context.temp_allocator)
    // defer strings.builder_destroy(&result) // this is not correct usage?

    // fmt.println(len(text))

    alloc := runtime.default_allocator()
    fmt.println(alloc)
    
    result := strings.builder_make(alloc)
    // lexeme := strings.builder_make(alloc) // helper to store lexemes
    // strings.builder_grow(&lexeme, 100)

    // strings.builder_init_len(&result, len(text)*64)
    // strings.builder_init_len(&lexeme, len(text)*64)

    // defer strings.builder_destroy(&lexeme)

    // fmt.println("1")
    
    index: int = 0
    for index < len(text) {
        if text[index] == ' ' || text[index] == '\t' || text[index] == '\n' {
            index += 1
            continue
        }

        // comment
        if text[index] == '-' {
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            defer strings.builder_destroy(&lexeme)

            strings.write_byte(&lexeme, text[index]) // add '-' to lexeme buffer
            
            if index + 1 < len(text) && text[index + 1] == '-' {
                start_pos := index
                strings.write_byte(&lexeme, text[index + 1])
                index += 2
                for index < len(text) && text[index] != '\n' {
                    strings.write_byte(&lexeme, text[index])
                    index += 1
                }

                fmt.sbprint(&result, "COMMENT", index, strings.to_string(lexeme))
            } else {
                // strings.write_string(&result, fmt.aprintf("ERROR %v %s\n", index, strings.to_string(lexeme)))
                fmt.sbprint(&result, "ERROR", index, strings.to_string(lexeme))
                index += 1
            }
            continue
        }

        // // header
        // if text[index] == '[' {
        //     start_pos := index
        //     lexeme := strings.builder_make(context.temp_allocator)
        //     // defer strings.builder_destroy(&lexeme)
            
        //     strings.write_byte(&lexeme, text[index]) // add '[' to lexeme buffer
        //     index += 1
        //     for index < len(text) && text[index] != ']' {
        //         strings.write_byte(&lexeme, text[index])
        //         index += 1
        //     }
        //     if index < len(text) && text[index] == ']' {
        //         strings.write_byte(&lexeme, text[index]) // add ']' to lexeme buffer
        //         index += 1
        //     }
        //     strings.write_string(result, fmt.aprintf("KEYWORD %v %s\n", start_pos, strings.to_string(lexeme)))
        //     continue
        // }

        // // string
        // if text[index] == '"' || text[index] == '\'' {
        //     start_pos := index
        //     lexeme := strings.builder_make(context.temp_allocator)
        //     // defer strings.builder_destroy(&lexeme)
            
        //     strings.write_byte(&lexeme, text[index]) // add '"' to lexeme buffer
        //     index += 1
        //     for index < len(text) && text[index] != '"' {
        //         strings.write_byte(&lexeme, text[index])
        //         index += 1
        //     }
        //     if index < len(text) && text[index] == '"' {
        //         strings.write_byte(&lexeme, text[index]) // add '"' to lexeme buffer
        //         index += 1
        //     }
        //     strings.write_string(result, fmt.aprintf("STRING %v %s\n", start_pos, strings.to_string(lexeme)))
        //     continue
        // }

        // // number
        // if text[index] >= '0' && text[index] <= '9' {
        //     start_pos := index
        //     lexeme := strings.builder_make(context.temp_allocator)
        //     // defer strings.builder_destroy(&lexeme)
            
        //     for index < len(text) && text[index] >= '0' && text[index] <= '9' {
        //         strings.write_byte(&lexeme, text[index])
        //         index += 1
        //     }
        //     strings.write_string(result, fmt.aprintf("NUMBER %v %s\n", start_pos, strings.to_string(lexeme)))
        //     continue
        // }

        // // conditional | name | identifier
        // if (text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' {
        //     start_pos := index
        //     lexeme := strings.builder_make(context.temp_allocator)
        //     // defer strings.builder_destroy(&lexeme)
            
        //     for index < len(text) && ((text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' || (text[index] >= '0' && text[index] <= '9')) {
        //         strings.write_byte(&lexeme, text[index])
        //         index += 1
        //     }

        //     if is_conditional(strings.to_string(lexeme)) {
        //         strings.write_string(result, fmt.aprintf("CONDITIONAL %v %s\n", start_pos, strings.to_string(lexeme)))
        //     } else if is_name(strings.to_string(lexeme)) {
        //         strings.write_string(result, fmt.aprintf("NAME %v %s\n", start_pos, strings.to_string(lexeme)))
        //     } else {
        //         strings.write_string(result, fmt.aprintf("IDENTIFIER %v %s\n", start_pos, strings.to_string(lexeme)))
        //     }
        //     continue
        // }

        // lexeme := strings.builder_make(context.temp_allocator)
        // // defer strings.builder_destroy(&lexeme)
        
        // strings.write_byte(&lexeme, text[index])
        // strings.write_string(result, fmt.aprintf("ERROR %v %s\n", index, strings.to_string(lexeme)))
        // index += 1
    }

    return strings.to_string(result)
}

// odin run test
// odin build test -build-mode:dll

@export process_input :: proc(arg: string) -> string {
    fmt.println("Odin : Received argument : ", arg);

    // alloc := runtime.default_allocator()

    // result := strings.builder_make(context.temp_allocator)
    // lexeme := strings.builder_make(context.temp_allocator) // helper to store lexemes
    
    result := tokenize(arg)

    // result := strings.builder_make(alloc)
    
    // strings.write_string(&result, "a")     // 1
    // strings.write_string(&result, "bc")    // 2
    
    // fmt.println(strings.to_string(result)) // -> abc

    fmt.println("Odin : tokenize done :", result)
    
    // free_all(context.temp_allocator)

    return result
}

// main :: proc() {
//     fmt.println("main", "called")
//     fmt.println(runtime.default_allocator().procedure)
//     // TEXT :: `
//     //     [header]
//     //     -- comment
//     //     font "Fira Code"
//     //     font_size 23
//     // `
//     // KEYWORD 9 [header]
//     // COMMENT 26 -- comment
//     // NAME 45 font
//     // STRING 50 "Fira Code"
//     // NAME 70 font_size
//     // NUMBER 80 23

//     // for arg in os.args {
//     //     fmt.println(arg)
//     // }

//     // result := strings.builder_make(context.temp_allocator)

//     // // tokenize(os.args[1], &result)

//     // tokenize(TEXT, &result)

//     // // result := tokenize(TEXT)
//     // // defer delete(result) // todo : is this correct?
//     // // defer strings.builder_destroy(result)
    
//     // fmt.println(strings.to_string(result))

//     // free_all(context.temp_allocator)

//     // fmt.println("Starting test")

//     // result := strings.builder_make()
//     // defer strings.builder_destroy(&result)

//     // fmt.println("Finished test")
// }


