
# MIT License

# Copyright 2025 @asyncze (Michael Sjöberg)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Tokenizer for Hackerman DSCL (.pyx-version)

# cython: language_level=3
cimport cython

cdef str WHITESPACE = "whitespace"
cdef str DEFAULT = "default"
cdef str KEYWORD = "keyword"
cdef str CLASS = "class"
cdef str NAME = "name"
cdef str PARAMETER = "parameter"
cdef str LAMBDA = "lambda"
cdef str STRING = "string"
cdef str NUMBER = "number"
cdef str OPERATOR = "operator"
cdef str COMMENT = "comment"
cdef str SPECIAL = "special"
cdef str TYPE = "type"
cdef str CONDITIONAL = "conditional"
cdef str BUILT_IN = "built_in"
# system colors
cdef str ERROR = "error"
cdef str WARNING = "warning"
cdef str SUCCESS = "success"

ACCEPTED_NAMES = frozenset({ 
    
    # editor
    "font",
    "font_weight",
    "font_size",
    "tab_width",
    "cursor_width",
    "editor_margin",
    "scrollbar_width",
    "scrollbar_opacity",
    "line_number_opacity",
    "window_opacity",
    "theme",
    "file_explorer_root",
    "model_to_use",
    "eol_mode",
    "folded_code_indicator",
    
    # toggles
    "show_line_numbers",
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
    "autocomplete",
    "auto_indent",
    "debug_mode",
    "focus_mode",
    "adaptive_cursor",

    "auto_close_single_quote",
    "auto_close_double_quote",
    "auto_close_square_bracket",
    "auto_close_curly_bracket",
    "auto_close_parentheses",

    # status bar
    "show_path_to_file",
    "show_active_tokenizer",
    "show_model_status",
    "show_cursor_position",

    # models
    "code_completion",
    "code_instruction",

    "model",
    "key",

    # keybinds
    "save_file",
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

    # colors
    "background",
    "foreground",
    "selection",
    "selection_inactive",
    "text_color",
    "text_highlight",
    "cursor",
    "whitespace",
    
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
    "special",
    "type",
    "conditional",
    "built_in",

    "error",
    "warning",
    "success",
})

cdef int handle_whitespace(int current_char_index):
    current_char_index += 1
    return current_char_index

cdef int handle_comment(int current_char_index, str text, list tokens):
    cdef int start_pos = current_char_index
    cdef str line = text[current_char_index]
    current_char_index += 1

    while current_char_index < len(text) and text[current_char_index] != '\n':
        line += text[current_char_index]
        current_char_index += 1

    tokens.append((COMMENT, start_pos, line))
    return current_char_index

cdef int handle_header(int current_char_index, str text, list tokens):
    cdef int start_pos = current_char_index
    cdef str lexeme = text[current_char_index] # should be '['
    current_char_index += 1

    while current_char_index < len(text) and text[current_char_index] != ']':
        lexeme += text[current_char_index]
        current_char_index += 1

    if current_char_index < len(text) and text[current_char_index] == ']':
        lexeme += text[current_char_index]
        current_char_index += 1

    tokens.append((KEYWORD, start_pos, lexeme))
    return current_char_index

cdef int handle_string(int current_char_index, str text, list tokens):
    cdef int start_pos = current_char_index
    cdef str quote = text[current_char_index]
    cdef str lexeme = quote
    current_char_index += 1

    while current_char_index < len(text) and text[current_char_index] != quote and text[current_char_index] != '\n':
        lexeme += text[current_char_index]
        current_char_index += 1

    if current_char_index < len(text) and text[current_char_index] == quote:
        lexeme += text[current_char_index]
        current_char_index += 1

    tokens.append((STRING, start_pos, lexeme))
    return current_char_index

cdef int handle_number(int current_char_index, str text, list tokens):
    cdef int start_pos = current_char_index
    cdef str lexeme = ""

    while current_char_index < len(text) and (text[current_char_index].isdigit() or text[current_char_index] == '.'):
        lexeme += text[current_char_index]
        current_char_index += 1

    tokens.append((NUMBER, start_pos, lexeme))
    return current_char_index

cdef int handle_identifier(int current_char_index, str text, list tokens):
    cdef int start_pos = current_char_index
    cdef str lexeme = ""

    while current_char_index < len(text) and (text[current_char_index].isalnum() or text[current_char_index] == '_'):
        lexeme += text[current_char_index]
        current_char_index += 1

    if lexeme in { "true", "false" }:
        tokens.append((CONDITIONAL, start_pos, lexeme))
    
    elif lexeme in ACCEPTED_NAMES: # TODO
        tokens.append((DEFAULT, start_pos, lexeme))
    
    else:
        tokens.append((ERROR, start_pos, lexeme))

    return current_char_index

@cython.cclass
class Lexer:

    @property
    def lexer_name(self): return "Hackerman Config"

    @property
    def comment_char(self): return "--"

    def tokenize(self, str text):
        cdef int current_char_index = 0
        cdef str current_char
        cdef str next_char
        cdef list tokens = []

        while current_char_index < len(text):
            current_char = text[current_char_index]
            next_char = text[current_char_index] if current_char_index + 1 < len(text) else ""

            # whitespace
            if current_char in { ' ', '\t', '\r', '\n' }: current_char_index = handle_whitespace(current_char_index)
            # comment
            elif current_char == '-' and next_char == '-': current_char_index = handle_comment(current_char_index, text, tokens)
            # header
            elif current_char == '[': current_char_index = handle_header(current_char_index, text, tokens)
            # string
            elif current_char in { '\"', '\'' }: current_char_index = handle_string(current_char_index, text, tokens)
            # number
            elif '0' <= current_char <= '9': current_char_index = handle_number(current_char_index, text, tokens)
            # identifier
            elif current_char.isalpha() or current_char == '_': current_char_index = handle_identifier(current_char_index, text, tokens)
            # symbols
            elif current_char in { '(', ')', ',' }:
                tokens.append((COMMENT, current_char_index, current_char))
                current_char_index += 1
            # unknown
            else:
                tokens.append((ERROR, current_char_index, current_char))
                current_char_index += 1

        return tokens
