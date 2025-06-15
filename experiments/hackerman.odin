
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

// odin build hackerman.odin -file -build-mode:dll

package hackerman_tokenizer

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

NAMES: [98]string = [98]string{
    "font", // editor
    "font_weight",
    "font_size",
    "tab_width",
    "cursor_width",
    "editor_margin",
    "scrollbar_width",
    "scrollbar_opacity",
    "line_number_opacity",
    "theme",
    "file_explorer_root",
    "model_to_use",
    "eol_mode",
    "show_line_numbers", // toggles
    "transparent",
    "cursor_as_block",
    "wrap_word",
    "blinking_cursor",
    "auto_hide_scrollbar",
    "show_minimap",
    "highlight_todos",
    "whitespace_visible",
    "indent_guides",
    "highlight_line",
    "highlight_line_on_jump",
    "show_eol",
    "file_explorer_hide_unsupported",
    "open_on_largest_screen",
    "auto_close_delimiters",
    "autocomplete",
    "auto_indent",
    "debug_mode",
    "show_path_to_file", // status bar
    "show_active_tokenizer",
    "show_model_status",
    "show_cursor_position",
    "model", // ollama, openai
    "key",
    "save_file", // bindings
    "new_file",
    "new_window",
    "open_file",
    "fold_line",
    "fold_all",
    "code_instruction",
    "code_completion",
    "code_explain",
    "code_suggestion",
    "line_indent",
    "line_unindent",
    "line_comment",
    "open_config_file",
    "open_functions_file",
    "move_to_line_start",
    "move_to_line_start_with_select",
    "zoom_in",
    "zoom_out",
    "split_view",
    "open_file_explorer",
    "open_folder_at_file",
    "open_terminal_at_file",
    "select_all",
    "find_in_file",
    "go_to_line",
    "undo",
    "redo",
    "previous_tab",
    "next_tab",
    "jump_to_home",
    "jump_to_end",
    "page_up",
    "page_down",
    "close_file",
    "background", // theme
    "foreground",
    "selection",
    "selection_inactive",
    "text_color",
    "text_highlight",
    "cursor",
    "whitespace", // syntax colors
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
    "type",
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

        // comment
        if runes[index] == '-' {
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)

            strings.write_rune(&lexeme, runes[index]) // add '-' to lexeme buffer
            
            // single-line comment
            if index + 1 < len(runes) && runes[index + 1] == '-' {
                start_pos := index
                strings.write_rune(&lexeme, runes[index + 1]) // add '-' to lexeme buffer
                index += 2
                
                for index < len(runes) && runes[index] != '\n' {
                    strings.write_rune(&lexeme, runes[index])
                    index += 1
                }
                
                append(&tokens, Token{ type = COMMENT, start_pos = start_pos, value = strings.to_string(lexeme) })
                
                continue
            }
            
            // error
            append(&tokens, Token{ type = ERROR, start_pos = index, value = strings.to_string(lexeme) })
            index += 1
            
            continue
        }

        // header
        if runes[index] == '[' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            strings.write_rune(&lexeme, runes[index]) // add '[' to lexeme buffer
            index += 1
            for index < len(runes) && text[index] != ']' {
                strings.write_rune(&lexeme, runes[index])
                index += 1
            }
            if index < len(runes) && runes[index] == ']' {
                strings.write_rune(&lexeme, runes[index]) // add ']' to lexeme buffer
                index += 1
            }
            
            append(&tokens, Token{ type = KEYWORD, start_pos = start_pos, value = strings.to_string(lexeme) })
            continue
        }

        // string
        if runes[index] == '"' || runes[index] == '\'' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            strings.write_rune(&lexeme, runes[index]) // add '"' to lexeme buffer
            index += 1
            for index < len(runes) && runes[index] != '"' && runes[index] != '\n' {
                strings.write_rune(&lexeme, runes[index])
                index += 1
            }
            if index < len(runes) && runes[index] == '"' {
                strings.write_rune(&lexeme, runes[index]) // add '"' to lexeme buffer
                index += 1
            }

            append(&tokens, Token{ type = STRING, start_pos = start_pos, value = strings.to_string(lexeme) })
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

        // conditional | name | identifier
        if (runes[index] >= 'a' && runes[index] <= 'z') || (runes[index] >= 'A' && runes[index] <= 'Z') || runes[index] == '_' {
            start_pos := index
            
            lexeme := strings.builder_make(alloc) // helper to store lexemes
            // defer strings.builder_destroy(&lexeme)
            
            for index < len(runes) && ((runes[index] >= 'a' && runes[index] <= 'z') || (runes[index] >= 'A' && runes[index] <= 'Z') || runes[index] == '_' || (runes[index] >= '0' && runes[index] <= '9')) {
                strings.write_rune(&lexeme, runes[index])
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
        
        strings.write_rune(&lexeme, runes[index])
        append(&tokens, Token{ type = ERROR, start_pos = index, value = strings.to_string(lexeme) })
        index += 1
    }

    return tokens
}

@export process_input :: proc(arg: string) -> [dynamic]Token {
    result := tokenize(arg)
    return result
}
