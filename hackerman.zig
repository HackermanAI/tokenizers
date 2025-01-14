
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

const std = @import("std");

const TokenType = enum(u8) {
    DEFAULT,
    WHITESPACE,
    COMMENT,
    OPERATOR,
    KEYWORD,
    BUILT_IN,
    SPECIAL,
    PARAMETER,
    CONDITIONAL,
    _ANON,
    NUMBER,
    STRING,
    NAME,
    IDENTIFIER,
    FSTRING,
    SPECIALC,
    ERROR,
    SUCCESS,
};

pub const Token = struct {
    tokenType: TokenType,
    startPos: usize,
    value: []const u8,

    pub fn init(tokenType: TokenType, startPos: usize, value: []const u8) Token {
        return Token{
            .tokenType = tokenType,
            .startPos = startPos,
            .value = value,
        };
    }
};

// pub const Lexer = extern struct {
//     const NAMES = [_][]const u8{
//         "font", "font_weight", "font_size", "tab_width", "cursor_width", "margin",
//         "theme", "file_explorer_root", "model_to_use", "eol_mode",
//         // toggles
//         "show_line_numbers", "transparent", "blockcursor", "wrap_word",
//         "blinking_cursor", "show_scrollbar", "show_minimap", "highlight_todos",
//         "whitespace_visible", "indent_guides", "highlight_current_line",
//         "highlight_current_line_on_jump", "show_eol",
//         // ollama
//         // openai
//         "model", "key",
//         // key bindings
//         "save_file", "new_file", "new_window", "open_file", "fold_all",
//         "command_k", "line_indent", "line_unindent", "line_comment", "set_bookmark",
//         "open_config_file", "build_and_run", "move_to_line_start",
//         "move_to_line_start_with_select", "zoom_in", "zoom_out", "toggle_file_explorer",
//         "split_view", "find_in_file", "undo", "redo", "background",
//         // theme
//         "foreground", "selection", "selection_inactive", "text_color",
//         "text_highlight", "cursor", "whitespace", "default", "keyword",
//         "class", "name", "parameter", "lambda", "string", "number",
//         "operator", "comment", "error", "warning", "success", "special",
//         "conditional", "built_in",
//     };

//     const CONDITIONALS = [_][]const u8{
//         "true",
//         "false",
//     };
// };

const NAMES = [_][]const u8{
    "font", "font_weight", "font_size", "tab_width", "cursor_width", "margin",
    "theme", "file_explorer_root", "model_to_use", "eol_mode",
    // toggles
    "show_line_numbers", "transparent", "blockcursor", "wrap_word",
    "blinking_cursor", "show_scrollbar", "show_minimap", "highlight_todos",
    "whitespace_visible", "indent_guides", "highlight_current_line",
    "highlight_current_line_on_jump", "show_eol",
    // ollama
    // openai
    "model", "key",
    // key bindings
    "save_file", "new_file", "new_window", "open_file", "fold_all",
    "command_k", "line_indent", "line_unindent", "line_comment", "set_bookmark",
    "open_config_file", "build_and_run", "move_to_line_start",
    "move_to_line_start_with_select", "zoom_in", "zoom_out", "toggle_file_explorer",
    "split_view", "find_in_file", "undo", "redo", "background",
    // theme
    "foreground", "selection", "selection_inactive", "text_color",
    "text_highlight", "cursor", "whitespace", "default", "keyword",
    "class", "name", "parameter", "lambda", "string", "number",
    "operator", "comment", "error", "warning", "success", "special",
    "conditional", "built_in",
};

const CONDITIONALS = [_][]const u8{
    "true",
    "false",
};

// const NAMES = enum {
//     font,
//     font_weight,
//     font_size,
//     tab_width,
//     cursor_width,
//     margin,
//     theme,
//     file_explorer_root,
//     model_to_use,
//     eol_mode,
//     show_line_numbers,
//     transparent,
//     blockcursor,
//     wrap_word,
//     blinking_cursor,
//     show_scrollbar,
//     show_minimap,
//     highlight_todos,
//     whitespace_visible,
//     indent_guides,
//     highlight_current_line,
//     highlight_current_line_on_jump,
//     show_eol,
//     model,
//     key,
//     save_file,
//     new_file,
//     new_window,
//     open_file,
//     fold_all,
//     command_k,
//     line_indent,
//     line_unindent,
//     line_comment,
//     set_bookmark,
//     open_config_file,
//     build_and_run,
//     move_to_line_start,
//     move_to_line_start_with_select,
//     zoom_in,
//     zoom_out,
//     toggle_file_explorer,
//     split_view,
//     find_in_file,
//     undo,
//     redo,
//     background,
//     foreground,
//     selection,
//     selection_inactive,
//     text_color,
//     text_highlight,
//     cursor,
//     whitespace,
//     default_token,
//     keyword,
//     class,
//     name,
//     parameter,
//     lambda,
//     string,
//     number,
//     operator,
//     comment,
//     _error,
//     warning,
//     success,
//     special,
//     conditional,
//     built_in,
// };

// const CONDITIONALS = enum {
//     true,
//     false,
// };

pub fn isAlpha(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z');
}

pub fn isAlphaNum(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9');
}

pub export fn tokenize(text: [*]const u8) [*]Token {
    const allocator = std.heap.page_allocator;
    var tokens = std.ArrayList(Token).init(allocator);

    var index: usize = 0;
    var currentLine: usize = 1;
    var currentHeader: ?[]const u8 = null;
    var rhs: bool = false;

    // while (index < text.len) {
    while (true) {
        const char = text[index];
        if (char == 0) break; // stop at null terminator

        const currentChar = text[index];
        switch (currentChar) {
            ' ', '\t', '\r' => {
                index += 1;
            },
            '\n' => {
                currentLine += 1;
                index += 1;
                rhs = false;
            },
            '-' => {
                if (text[index + 1] == '-' and text[index + 1] != 0) {
                    const start = index;
                    index += 2;
                    while (text[index + 1] != 0 and text[index] != '\n') {
                        index += 1;
                    }
                    const result = tokens.append(Token.init(TokenType.COMMENT, start, text[start..index]));
                    if (result catch null) |err| {
                        std.debug.print("Out of memory when appending token: {}\n", .{err});
                        break;
                    }
                } else {
                    const result = tokens.append(Token.init(TokenType.ERROR, index, text[index..index + 1]));
                    if (result catch null) |err| {
                        std.debug.print("Out of memory when appending token: {}\n", .{err});
                        break;
                    }
                    index += 1;
                }
            },
            '[' => {
                const start = index;
                index += 1;
                var headerEnd = start;

                while (text[index + 1] != 0 and text[index] >= 0x20 and text[index] <= 0x7E) {
                    if (text[index] == ']') {
                        headerEnd = index + 1;
                        break;
                    }
                    index += 1;
                }

                if (headerEnd > start) {
                    currentHeader = text[start..headerEnd];
                    const result = tokens.append(Token.init(TokenType.KEYWORD, start, text[start..headerEnd]));
                    if (result catch null) |err| {
                        std.debug.print("Out of memory when appending token: {}\n", .{err});
                        break;
                    }
                } else {
                    const result = tokens.append(Token.init(TokenType.ERROR, start, text[start..index]));
                    if (result catch null) |err| {
                        std.debug.print("Out of memory when appending token: {}\n", .{err});
                        break;
                    }
                }
            },
            '\"', '\'' => {
                const start = index;
                const quoteChar = currentChar;
                index += 1;

                while (text[index + 1] != 0 and text[index] >= 0x20 and text[index] <= 0x7E) {
                    if (text[index] == quoteChar) {
                        index += 1;
                        break;
                    }
                    index += 1;
                }

                const result = tokens.append(Token.init(TokenType.STRING, start, text[start..index]));
                if (result catch null) |err| {
                    std.debug.print("Out of memory when appending token: {}\n", .{err});
                    break;
                }
            },
            else => {
                if (currentChar >= '0' and currentChar <= '9') {
                    const start = index;
                    while (text[index + 1] != 0 and (text[index] >= '0' and text[index] <= '9' or text[index] == '.')) {
                        index += 1;
                    }
                    const result = tokens.append(Token.init(TokenType.NUMBER, start, text[start..index]));
                    if (result catch null) |err| {
                        std.debug.print("Out of memory when appending token: {}\n", .{err});
                        break;
                    }
                } else if (isAlpha(currentChar)) {
                    const start = index;
                    while (text[index + 1] != 0 and isAlphaNum(text[index])) {
                        index += 1;
                    }

                    const identifier = text[start..index];

                    const result = tokens.append(Token.init(TokenType.DEFAULT, start, identifier));
                    if (result catch null) |err| {
                        std.debug.print("Out of memory when appending token: {}\n", .{err});
                        break;
                    }

                    // const identifier = text[start..index];
                    // var found: bool = false;

                    // for (NAMES) |name| {
                    //     if (std.mem.eql(u8, name, identifier)) {
                    //         found = true;
                    //         const result = tokens.append(Token.init(TokenType.DEFAULT, start, identifier));
                    //         if (result catch null) |err| {
                    //             std.debug.print("Out of memory when appending token: {}\n", .{err});
                    //             break;
                    //         }
                    //     }
                    // }

                    // for (CONDITIONALS) |conditional| {
                    //     if (std.mem.eql(u8, conditional, identifier)) {
                    //         found = true;
                    //         const result = tokens.append(Token.init(TokenType.CONDITIONAL, start, identifier));
                    //         if (result catch null) |err| {
                    //             std.debug.print("Out of memory when appending token: {}\n", .{err});
                    //             break;
                    //         }
                    //     }
                    // }

                    // if (!found) {
                    //     const result = tokens.append(Token.init(TokenType.ERROR, start, identifier));
                    //     if (result catch null) |err| {
                    //         std.debug.print("Out of memory when appending token: {}\n", .{err});
                    //         break;
                    //     }
                    // }
                } else {
                    const result = tokens.append(Token.init(TokenType.ERROR, index, text[index..index + 1]));
                    if (result catch null) |err| {
                        std.debug.print("Out of memory when appending token: {}\n", .{err});
                        break;
                    }
                    index += 1;
                }
            },
        }
    }

    const result = tokens.toOwnedSlice();
    std.debug.print("{any}\n", .{result});

    if (result) |tokens_slice| {
        return tokens_slice.ptr;
    } else |err| {
        std.debug.print("Error: {any}\n", .{err});
        
        // const empty_slice: []Token = [*]Token{};
        const empty_slice: []Token = &.{};
        return empty_slice.ptr;
    }
}

