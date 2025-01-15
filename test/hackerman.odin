
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

TokenType :: enum {
    COMMENT,
    ERROR,
    KEYWORD,
    STRING,
    NUMBER,
    CONDITIONAL,
    NAME,
    IDENTIFIER,
    DEFAULT,
}

Token :: struct {
    type_: TokenType,
    start_pos: int,
    value: [dynamic]u8,
}

@export
tokenize :: proc(text: string) -> [dynamic]Token {
    // tokens: []Token = []Token{} // List of tokens
    tokens: [dynamic]Token

    // builder := strings.Builder
    // defer builder.builder_destroy()
    
    index: int = 0
    for index < len(text) {
        if text[index] == ' ' || text[index] == '\t' || text[index] == '\n' {
            index += 1
            continue
        }

        if text[index] == '-' {
            // lexeme_data: []u8 = []u8{}
            // lexeme_data = append(lexeme_data, text[index])

            // newstr: string = string(text[index])

            // b := strings.builder_make()
            // strings.write_string(&b, newstr)
            // str := strings.to_string(b)
            // fmt.println(str)

            lexeme: [dynamic]u8
            append(&lexeme, text[index])

            if index + 1 < len(text) && text[index + 1] == '-' {
                start_pos := index
                append(&lexeme, text[index + 1])
                index += 2
                for index < len(text) && text[index] != '\n' {
                    append(&lexeme, text[index])
                    index += 1
                }
                append(&tokens, Token{type_ = TokenType.COMMENT, start_pos = start_pos, value = lexeme})
            } else {
                append(&tokens, Token{type_ = TokenType.ERROR, start_pos = index, value = lexeme})
                index += 1
            }
            continue
        }

        // if text[index] == '[' {
        //     start_pos := index
        //     lexeme := "["
        //     index += 1
        //     for index < len(text) && text[index] != ']' {
        //         lexeme += string(text[index])
        //         index += 1
        //     }
        //     if index < len(text) && text[index] == ']' {
        //         lexeme += "]"
        //         index += 1
        //     }
        //     tokens = append(tokens, Token{type_ = KEYWORD, start_pos = start_pos, value = lexeme})
        //     continue
        // }

        // if text[index] == '"' || text[index] == '\'' {
        //     start_pos := index
        //     quote := text[index]
        //     lexeme := string(quote)
        //     index += 1
        //     for index < len(text) && text[index] != quote {
        //         lexeme += string(text[index])
        //         index += 1
        //     }
        //     if index < len(text) && text[index] == quote {
        //         lexeme += string(quote)
        //         index += 1
        //     }
        //     tokens = append(tokens, Token{type_ = STRING, start_pos = start_pos, value = lexeme})
        //     continue
        // }

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

        lexeme: [dynamic]u8
        append(&lexeme, text[index])
        append(&tokens, Token{type_ = TokenType.DEFAULT, start_pos = index, value = lexeme})
        index += 1
    }

    return tokens
}
