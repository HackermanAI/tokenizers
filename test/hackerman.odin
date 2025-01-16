
// odin build test -build-mode:dll
package test

import "core:fmt"
import "core:mem"
import "core:strings"

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

@export tokenize :: proc(text: string) -> string {
    result := strings.builder_make()
    
    index: int = 0
    for index < len(text) {
        if text[index] == ' ' || text[index] == '\t' || text[index] == '\n' {
            index += 1
            continue
        }

        // comment
        if text[index] == '-' {
            lexeme := strings.builder_make()
            strings.write_byte(&lexeme, text[index]) // add '-' to lexeme buffer
            if index + 1 < len(text) && text[index + 1] == '-' {
                start_pos := index
                strings.write_byte(&lexeme, text[index + 1])
                index += 2
                for index < len(text) && text[index] != '\n' {
                    strings.write_byte(&lexeme, text[index])
                    index += 1
                }
                strings.write_string(&result, fmt.aprintf("COMMENT %v %s\n", start_pos, strings.to_string(lexeme)))
            } else {
                strings.write_string(&result, fmt.aprintf("ERROR %v %s\n", index, strings.to_string(lexeme)))
                index += 1
            }
            continue
        }

        // header
        if text[index] == '[' {
            start_pos := index
            lexeme := strings.builder_make()
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
            strings.write_string(&result, fmt.aprintf("KEYWORD %v %s\n", start_pos, strings.to_string(lexeme)))
            continue
        }

        // string
        if text[index] == '"' || text[index] == '\'' {
            start_pos := index
            lexeme := strings.builder_make()
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
            strings.write_string(&result, fmt.aprintf("STRING %v %s\n", start_pos, strings.to_string(lexeme)))
            continue
        }

        // if text[index] >= '0' && text[index] <= '9' {
        //     start_pos := index
        //     lexeme := ""
        //     for index < len(text) && text[index] >= '0' && text[index] <= '9' {
        //         lexeme += string(text[index])
        //         index += 1
        //     }
        //     tokens = append(tokens, Token{type_ = NUMBER, start_pos = start_pos, value = lexeme})
        //     continue
        // }

        // if (text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' {
        //     start_pos := index
        //     buffer := strings.make(128)
        //     defer mem.free(buffer.data)

        //     length: usize = 0
        //     for index < len(text) && ((text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' || (text[index] >= '0' && text[index] <= '9')) {
        //         buffer[length] = text[index]
        //         length += 1
        //         index += 1
        //     }
        //     buffer[length] = u8(0)
        //     lexeme := string(buffer[:length])

        //     if is_conditional(lexeme) {
        //         tokens = append(tokens, Token{type_ = CONDITIONAL, start_pos = start_pos, value = lexeme})
        //     } else if is_name(lexeme) {
        //         tokens = append(tokens, Token{type_ = NAME, start_pos = start_pos, value = lexeme})
        //     } else {
        //         tokens = append(tokens, Token{type_ = IDENTIFIER, start_pos = start_pos, value = lexeme})
        //     }
        //     continue
        // }

        lexeme := strings.builder_make()
        strings.write_byte(&lexeme, text[index])
        strings.write_string(&result, fmt.aprintf("ERROR %v %s\n", index, strings.to_string(lexeme)))
        index += 1
    }

    // joined_string := tokens_to_string(tokens)

    return strings.to_string(result)
}

// for testing only
main :: proc() {
    result := tokenize("[header]\n-- comment\n\"font\"")
    defer delete(result)
    
    fmt.println(result)
}


