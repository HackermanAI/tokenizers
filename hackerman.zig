const std = @import("std");
const Allocator = std.mem.Allocator;
pub const TokenType = enum {
    COMMENT,
    ERROR,
    KEYWORD,
    STRING,
    NUMBER,
    CONDITIONAL,
    NAME,
    IDENTIFIER,
    DEFAULT,
};

pub const Token = struct {
    token_type: TokenType,
    start: usize,
    value: [*]const u8,
};

pub const TokenArray = struct {
    ptr: ?[*]Token,
    len: usize,
    cap: usize,
};

const names = [_][]const u8{
    "font",                   "font_weight",                    "font_size",          "tab_width",          "cursor_width",
    "margin",                 "theme",                          "file_explorer_root", "model_to_use",       "eol_mode",
    "show_line_numbers",      "transparent",                    "blockcursor",        "wrap_word",          "blinking_cursor",
    "show_scrollbar",         "show_minimap",                   "highlight_todos",    "whitespace_visible", "indent_guides",
    "highlight_current_line", "highlight_current_line_on_jump", "show_eol",
};

fn isName(value: []const u8) bool {
    for (names) |name| {
        if (std.mem.eql(u8, name, value)) {
            return true;
        }
    }
    return false;
}

fn isConditional(value: []const u8) bool {
    return std.mem.eql(u8, value, "true") or std.mem.eql(u8, value, "false");
}

pub export fn tokenize(text: [*:0]const u8, out_tokens: *TokenArray) void {
    const allocator = std.heap.page_allocator;

    const tokens_ptr = allocator.alloc(Token, 100) catch {
        // return TokenArray{ .ptr = null, .len = 0, .cap = 0 };
        out_tokens.* = TokenArray{ .ptr = null, .len = 0, .cap = 0 };
        return;
    };

    const tokens = TokenArray{
        .ptr = @ptrCast(?[*]Token, tokens_ptr),
        .len = 0,
        .cap = 100,
    };

    var index: usize = 0;
    const text_len = text.len;

    while (index < text_len) {
        const c = text[index];

        // Skip whitespace
        if (std.unicode.isWhitespace(c)) {
            index += 1;
            continue;
        }

        const start_pos = index;

        // Comment
        if (c == '-' and index + 1 < text_len and text[index + 1] == '-') {
            index += 2;
            while (index < text_len and text[index] != '\n') {
                index += 1;
            }
            try tokens.append(.{ .token_type = .COMMENT, .start = start_pos, .value = text[start_pos..index] });
            continue;
        }

        // Header
        if (c == '[') {
            index += 1;
            while (index < text_len and text[index] != ']') {
                index += 1;
            }
            if (index < text_len and text[index] == ']') {
                index += 1;
            }
            try tokens.append(.{ .token_type = .KEYWORD, .start = start_pos, .value = text[start_pos..index] });
            continue;
        }

        // String
        if (c == '"' or c == '\'') {
            const quote = c;
            index += 1;
            while (index < text_len and text[index] != quote) {
                index += 1;
            }
            if (index < text_len and text[index] == quote) {
                index += 1;
            }
            try tokens.append(.{ .token_type = .STRING, .start = start_pos, .value = text[start_pos..index] });
            continue;
        }

        // Number
        if (std.unicode.isDigit(c)) {
            index += 1;
            while (index < text_len and std.unicode.isDigit(text[index])) {
                index += 1;
            }
            try tokens.append(.{ .token_type = .NUMBER, .start = start_pos, .value = text[start_pos..index] });
            continue;
        }

        // Identifier, Conditional, or Name
        if (std.unicode.isAlpha(c) or c == '_') {
            index += 1;
            while (index < text_len and (std.unicode.isAlnum(text[index]) or text[index] == '_')) {
                index += 1;
            }
            const value = text[start_pos..index];
            if (isConditional(value)) {
                try tokens.append(.{ .token_type = .CONDITIONAL, .start = start_pos, .value = value });
            } else if (isName(value)) {
                try tokens.append(.{ .token_type = .NAME, .start = start_pos, .value = value });
            } else {
                try tokens.append(.{ .token_type = .IDENTIFIER, .start = start_pos, .value = value });
            }
            continue;
        }

        // Default (unrecognized character)
        index += 1;
        try tokens.append(.{ .token_type = .DEFAULT, .start = start_pos, .value = text[start_pos..index] });
    }

    // return tokens.toOwnedSlice();
    // var tokens_ptr = try std.heap.page_allocator.alloc(Token, 100); // Adjust size as needed
    // const tokens = TokenArray{
    //     .ptr = tokens_ptr,
    //     .len = 0,
    //     .cap = 100,
    // };
    // Populate `tokens.ptr` with allocated token memory and `tokens.len`/`tokens.cap`
    // return tokens.*;
    out_tokens.* = tokens;
}

pub export fn free_tokens(tokens: *TokenArray) void {
    if (tokens.ptr) |ptr| {
        const allocator = std.heap.page_allocator;
        allocator.free(ptr);
        tokens.ptr = null;
        tokens.len = 0;
        tokens.cap = 0;
    }
}
