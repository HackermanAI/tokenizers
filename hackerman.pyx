
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

    # [editor]
    
    "system_font",
    "system_font_size",
    "system_font_weight",

    "editor_font",
    "editor_font_size",
    "editor_font_weight",

    "tab_width",
    "cursor_style",
    "cursor_width",
    "scrollbar_width",
    "eol_mode",
    "whitespace_symbol",
    "whitespace_visible",
    "editor_line_height",
    "blinking_cursor",

    "chat_start_symbol",
    "command_start_symbol",
    
    "window_opacity",
    "system_opacity",
    
    "theme",
    "adaptive_theme",
    "file_explorer_root",
    "file_explorer_in_sidebar",
    "terminal",
    "path_to_shell",
    "path_to_playlist",
    
    # -- toggles
    
    "ai_features",
    "show_line_numbers",
    "show_fold_margin",
    "show_audio_player",
    "wrap_word",
    "indent_guides",
    "highlight_line",
    "highlight_line_on_jump",
    "show_eol",
    "open_on_largest_screen",
    "autocomplete",
    "auto_indent",
    "replace_tabs_with_spaces",

    "auto_close_single_quote",
    "auto_close_double_quote",
    "auto_close_square_bracket",
    "auto_close_curly_bracket",
    "auto_close_parentheses",

    # -- status bar
    
    "show_line_info",
    "show_path_to_file",
    "show_active_lexer",
    "show_model_status",

    # [models]
    
    "code_completion",
    "code_instruction",
    "chat",

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
    "line_comment",
    "open_config_file",
    "open_scripts_file",
    "zoom_in",
    "zoom_out",
    "toggle_split_editor",
    "open_file_explorer",
    "open_folder_at_file",
    "open_terminal_at_file",
    
    "select_all",
    "undo",
    "redo",
    "lowercase",
    "uppercase",
    "cancel",
    "newline",
    "tab",
    "backtab",
    "center_on_cursor",
    "line_indent",
    "line_unindent",
    "selection_duplicate",
    "move_selected_lines_up",
    "move_selected_lines_down",

    "document_start",
    "document_end",
    "document_start_extend",
    "document_end_extend",

    "home",
    "home_extend",

    "char_left",
    "char_right",
    "char_left_extend",
    "char_right_extend",
    "line_up",
    "line_down",
    "line_up_extend",
    "line_down_extend",
    "line_start",
    "line_end",
    "line_start_extend",
    "line_end_extend",
    "line_scroll_up",
    "line_scroll_down",
    "line_add_caret_up",
    "line_add_caret_down",
    "line_delete",
    "line_duplicate",
    "line_transpose",
    "line_reverse",

    "copy",
    "cut",
    "paste",

    "para_up",
    "para_down",
    "para_up_extend",
    "para_down_extend",
    "word_left",
    "word_right",
    "word_left_extend",
    "word_right_extend",
    "word_left_end",
    "word_right_end",
    "word_left_end_extend",
    "word_right_end_extend",
    "word_part_left",
    "word_part_right",
    "word_part_left_extend",
    "word_part_right_extend",
    "page_up",
    "page_down",
    "page_up_extend",
    "page_down_extend",
    "stuttered_page_up",
    "stuttered_page_down",
    "stuttered_page_up_extend",
    "stuttered_page_down_extend",

    "delete",
    "delete_not_newline",

    "delete_right",

    "delete_word_left",
    "delete_word_right",
    "delete_line_left",
    "delete_line_right",
    "delete_para_left",
    "delete_para_right",

    "find_in_file",
    "find_in_project",
    
    "close_file",

    "command_chat_complete",
    "python_eval_line",
    "toggle_audio_player",
    "toggle_play",
    "move_to_prev_pos",
    
    "start_command",
    "start_chat",

    # pane navigation
    "focus_main_editor",
    "focus_split_editor",
    "previous_tab",
    "next_tab",

    "switch_to_buffer_1",
    "switch_to_buffer_2",
    "switch_to_buffer_3",
    "switch_to_buffer_4",
    "switch_to_buffer_5",
    "switch_to_buffer_6",
    "switch_to_buffer_7",
    "switch_to_buffer_8",
    "switch_to_buffer_9",

    # colors
    "background",
    "foreground",
    "selection",
    "selection_inactive",
    "text_color",
    "text_highlight",
    "cursor",
    "whitespace",

    "editor_bg",
    "editor_handle",
    
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
    
    elif lexeme in ACCEPTED_NAMES:
        tokens.append((DEFAULT, start_pos, lexeme))
    
    else:
        tokens.append((ERROR, start_pos, lexeme))

    return current_char_index


@cython.cclass
class Lexer:

    @property
    def lexer_name(self):
        return "Hackerman Config"

    @property
    def comment_char(self):
        return "--"

    @property
    def line_comment(self):
        return "--"

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

