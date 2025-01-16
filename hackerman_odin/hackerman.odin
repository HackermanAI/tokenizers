
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

package hackerman_odin

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

// @export free_memory :: proc () {
//     free_all(context.temp_allocator)
//     fmt.println("free_memory done")
// }

@export tokenize :: proc(text: string) -> string {
    // fmt.println("Odin : tokenize called :", text)

    alloc := runtime.default_allocator() // need to do this to not get assertion erron when calling from FFI
    // fmt.println(alloc)
    
    result := strings.builder_make(alloc)
    
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
                fmt.sbprint(&result, "COMMENT", start_pos, strings.to_string(lexeme), "\n")
            } else {
                fmt.sbprint(&result, "ERROR", index, strings.to_string(lexeme), "\n")
                index += 1
            }
            continue
        }

        // header
        if text[index] == '[' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            defer strings.builder_destroy(&lexeme)
            
            strings.write_byte(&lexeme, text[index]) // add '[' to lexeme buffer
            index += 1
            for index < len(text) && text[index] != ']' {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }
            if index < len(text) && text[index] == ']' {
                strings.write_byte(&lexeme, text[index]) // add ']' to lexeme buffer
                index += 1
            }
            fmt.sbprint(&result, "KEYWORD", start_pos, strings.to_string(lexeme), "\n")
            continue
        }

        // string
        if text[index] == '"' || text[index] == '\'' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            defer strings.builder_destroy(&lexeme)
            
            strings.write_byte(&lexeme, text[index]) // add '"' to lexeme buffer
            index += 1
            for index < len(text) && text[index] != '"' {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }
            if index < len(text) && text[index] == '"' {
                strings.write_byte(&lexeme, text[index]) // add '"' to lexeme buffer
                index += 1
            }
            fmt.sbprint(&result, "STRING", start_pos, strings.to_string(lexeme), "\n")
            continue
        }

        // number
        if text[index] >= '0' && text[index] <= '9' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            defer strings.builder_destroy(&lexeme)
            
            for index < len(text) && text[index] >= '0' && text[index] <= '9' {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }
            fmt.sbprint(&result, "NUMBER", start_pos, strings.to_string(lexeme), "\n")
            continue
        }

        // conditional | name | identifier
        if (text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            defer strings.builder_destroy(&lexeme)
            
            for index < len(text) && ((text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' || (text[index] >= '0' && text[index] <= '9')) {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }

            if is_conditional(strings.to_string(lexeme)) {
                fmt.sbprint(&result, "CONDITIONAL", start_pos, strings.to_string(lexeme), "\n")
            } else if is_name(strings.to_string(lexeme)) {
                fmt.sbprint(&result, "NAME", start_pos, strings.to_string(lexeme), "\n")
            } else {
                fmt.sbprint(&result, "IDENTIFIER", start_pos, strings.to_string(lexeme), "\n")
            }
            continue
        }

        lexeme := strings.builder_make(alloc) // helper to store lexemes
        defer strings.builder_destroy(&lexeme)
        
        strings.write_byte(&lexeme, text[index])
        fmt.sbprint(&result, "ERROR", index, strings.to_string(lexeme), "\n")
        index += 1
    }

    return strings.to_string(result)
}

// odin run hackerman_odin
// odin build hackerman_odin -build-mode:dll

@export process_input :: proc(arg: string) -> string {
    // fmt.println("Odin : received argument : ", arg);
    
    result := tokenize(arg)
    
    // fmt.println("Odin : tokenize done :", result)
    return result
}
