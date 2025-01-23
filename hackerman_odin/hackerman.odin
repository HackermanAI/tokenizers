
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

NAMES: [78]string = [78]string{
    // editor
    "font",
    "font_weight",
    "font_size",
    "tab_width",
    "cursor_width",
    "margin",
    "scrollbar_width",
    "scrollbar_opacity",
    "line_number_opacity",
    "theme",
    "file_explorer_root",
    "model_to_use",
    "eol_mode",
    // toggles
    "show_line_numbers",
    "transparent",
    "blockcursor",
    "wrap_word",
    "blinking_cursor",
    "auto_hide_scrollbar",
    "show_minimap",
    "highlight_todos",
    "whitespace_visible",
    "indent_guides",
    "highlight_current_line",
    "highlight_current_line_on_jump",
    "show_eol",
    // status bar
    "show_path_to_file",
    "show_active_tokenizer",
    "show_model_status",
    "show_cursor_position",
    // ollama
    // openai
    "model",
    "key",
    // bindings
    "save_file",
    "new_file",
    "new_window",
    "open_file",
    "fold_all",
    "command_k",
    "line_indent",
    "line_unindent",
    "line_comment",
    "set_bookmark",
    "open_config_file",
    "build_and_run",
    "move_to_line_start",
    "move_to_line_start_with_select",
    "zoom_in",
    "zoom_out",
    "toggle_file_explorer",
    "split_view",
    "select_all",
    "find_in_file",
    "undo",
    "redo",
    // theme
    "background",
    "foreground",
    "selection",
    "selection_inactive",
    "text_color",
    "text_highlight",
    "cursor",
    "whitespace",
    // syntax colors
    "default",
    "keyword",
    "class",
    "name",
    "parameter",
    "lambda",
    "string",
    "number",
    "operator",
    "comment",
    "error",
    "warning",
    "success",
    "special",
    "conditional",
    "built_in"
}

is_name :: proc(value: string) -> bool {
    for name in NAMES {
        if name == value {
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

        // comment
        if text[index] == '-' {
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)

            strings.write_byte(&lexeme, text[index]) // add '-' to lexeme buffer
            if index + 1 < len(text) && text[index + 1] == '-' {
                start_pos := index
                strings.write_byte(&lexeme, text[index + 1]) // add '-' to lexeme buffer
                index += 2
                for index < len(text) && text[index] != '\n' {
                    strings.write_byte(&lexeme, text[index])
                    index += 1
                }
                append(&tokens, Token{ type = COMMENT, start_pos = start_pos, value = strings.to_string(lexeme) })
            } else {
                append(&tokens, Token{ type = ERROR, start_pos = index, value = strings.to_string(lexeme) })
                index += 1
            }
            continue
        }

        // header
        if text[index] == '[' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            strings.write_byte(&lexeme, text[index]) // add '[' to lexeme buffer
            index += 1
            for index < len(text) && text[index] != ']' {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }
            strings.write_byte(&lexeme, text[index]) // add ']' to lexeme buffer
            index += 1
            
            append(&tokens, Token{ type = KEYWORD, start_pos = start_pos, value = strings.to_string(lexeme) })
            continue
        }

        // string
        if text[index] == '"' || text[index] == '\'' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            strings.write_byte(&lexeme, text[index]) // add '"' to lexeme buffer
            index += 1
            for index < len(text) && text[index] != '"' && text[index] != '\n' {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }
            if index < len(text) && text[index] == '"' {
                strings.write_byte(&lexeme, text[index]) // add '"' to lexeme buffer
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

        // conditional | name | identifier
        if (text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            for index < len(text) && ((text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' || (text[index] >= '0' && text[index] <= '9')) {
                strings.write_byte(&lexeme, text[index])
                index += 1
            }

            if is_conditional(strings.to_string(lexeme)) {
                append(&tokens, Token{ type = CONDITIONAL, start_pos = start_pos, value = strings.to_string(lexeme) })
            } else if is_name(strings.to_string(lexeme)) {
                append(&tokens, Token{ type = DEFAULT, start_pos = start_pos, value = strings.to_string(lexeme) })
            } else {
                append(&tokens, Token{ type = ERROR, start_pos = start_pos, value = strings.to_string(lexeme) })
            }
            continue
        }

        lexeme := strings.builder_make(alloc) // helper to store lexemes
        // defer strings.builder_destroy(&lexeme)
        
        strings.write_byte(&lexeme, text[index])
        append(&tokens, Token{ type = ERROR, start_pos = index, value = strings.to_string(lexeme) })
        index += 1
    }

    return tokens
}

// odin run hackerman_odin
// odin build hackerman_odin -build-mode:dll

@export process_input :: proc(arg: string) -> [dynamic]Token {    
    result := tokenize(arg)
    return result
}
