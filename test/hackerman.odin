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

// replace strings with other structure
tokenize :: proc(text: string) -> string {
    buffer: []u8 = []u8{} // Initialize a dynamic array
    index: int = 0

    for index < len(text) {
        if text[index] in ' ' || text[index] in '\t' || text[index] in '\n' {
            index += 1
            continue
        }

        if text[index] == '-' {
            if index + 1 < len(text) && text[index + 1] == '-' {
                buffer = append(buffer, "\nTYPE=COMMENT START="...)
                buffer = append(buffer, fmt.tprintf("%d VALUE=--", index)...)
                index += 2
                for index < len(text) && text[index] != '\n' {
                    buffer = append(buffer, text[index])
                    index += 1
                }
            } else {
                buffer = append(buffer, fmt.tprintf("\nTYPE=ERROR START=%d VALUE=-", index)...)
                index += 1
            }
            continue
        }

        if text[index] == '[' {
            start_pos := index
            fmt.append(result, "\nTYPE=KEYWORD START={%d} VALUE=[", start_pos)
            index += 1
            for index < len(text) && text[index] != ']' {
                fmt.append(result, "%c", text[index])
                index += 1
            }
            if index < len(text) && text[index] == ']' {
                fmt.append(result, "] ")
                index += 1
            }
            continue
        }

        if text[index] == '"' || text[index] == '\'' {
            start_pos := index
            quote := text[index]
            fmt.append(result, "\nTYPE=STRING START={%d} VALUE=", start_pos)
            fmt.append(result, "%c", quote)
            index += 1
            for index < len(text) && text[index] != quote {
                fmt.append(result, "%c", text[index])
                index += 1
            }
            if index < len(text) && text[index] == quote {
                fmt.append(result, "%c ", quote)
                index += 1
            }
            continue
        }

        if text[index] >= '0' && text[index] <= '9' {
            start_pos := index
            fmt.append(result, "\nTYPE=NUMBER START={%d} VALUE=", start_pos)
            for index < len(text) && text[index] >= '0' && text[index] <= '9' {
                fmt.append(result, "%c", text[index])
                index += 1
            }
            fmt.append(result, " ")
            continue
        }

        if (text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' {
            start_pos := index
            buffer := strings.make(128)
            defer mem.free(buffer.data)

            length: usize = 0

            for index < len(text) && ((text[index] >= 'a' && text[index] <= 'z') || (text[index] >= 'A' && text[index] <= 'Z') || text[index] == '_' || (text[index] >= '0' && text[index] <= '9')) {
                buffer[length] = text[index]
                length = 1
                index += 1
            }
            buffer[length] = u8(0)

            if is_conditional(buffer[:length]) {
                fmt.append(result, "\nTYPE=CONDITIONAL START={%d} VALUE=%s ", start_pos, buffer[:length])
            } else if is_name(buffer[:length]) {
                fmt.append(result, "\nTYPE=NAME START={%d} VALUE=%s ", start_pos, buffer[:length])
            } else {
                fmt.append(result, "\nTYPE=IDENTIFIER START={%d} VALUE=%s ", start_pos, buffer[:length])
            }
            continue
        }

        fmt.append(result, "\nTYPE=DEFAULT START={%d} VALUE=%c ", index, text[index])
        index += 1
    }

    return result
}
