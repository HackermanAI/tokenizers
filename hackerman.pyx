
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

    # [license]

    "product_key",

    # [editor]
    
    "ui_font",
    "ui_font_weight",
    "ui_font_size",

    "font",
    "font_weight",
    "font_size",

    "cursor_style",
    "whitespace_visible",
    "editor_line_height",
    
    "tab_width",
    "caret_blink_period",
    
    "window_opacity",
    "ui_opacity",
    
    "theme",
    "adaptive_theme",

    "file_explorer_root",
    
    "file_explorer_as_sidebar",
    "outline_panel_as_sidebar",
    
    "terminal_to_use",
    "path_to_shell",
    "path_to_playlist",
    
    "vertical_rulers",
    
    # -- toggles
    
    "ai_features_enabled",
    
    "show_line_numbers",
    "show_fold_margin",
    "show_scrollbar",
    "show_indent_guides",
    "show_now_playing",
    "blinking_cursor",
    "highlight_current_line",
    "eol_symbols_visible",
    "open_on_largest_screen",
    "autocomplete",
    "auto_indent",
    "replace_tabs_with_spaces",
    
    "wrap_word",
    "auto_close_tags",
    "highlight_line_on_jump",

    "copy_line_if_no_selection",
    "cut_line_if_no_selection",
    
    "use_buffer_switcher",

    # -- symbols

    "unsaved_symbol",
    "whitespace_symbol",
    "chat_start_symbol",
    "command_start_symbol",

    # -- advanced

    "auto_hide_fold_buttons",
    "eol_mode",

    "cursor_width",
    "caret_extra_height",
    "scrollbar_width",
    "whitespace_opacity",
    "indent_guides_opacity",
    "fade_scrollbar",
    "fade_split_handle",

    "auto_close_single_quote",
    "auto_close_double_quote",
    "auto_close_square_bracket",
    "auto_close_curly_bracket",
    "auto_close_parentheses",

    # -- status bar
    
    "show_line_info",
    "show_path_to_project",
    "show_active_lexer",
    "show_model_status",

    # [models]
    
    "code_completion",
    "code_instruction",
    "chat",

    # [keybinds]

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
    "move_line_up",
    "move_line_down",
    "copy_path_to_file",

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

    # -- pane navigation
    
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

    # [user]

    # this section is skipped

    # theme colors
    
    "background",
    "foreground",
    "selection",
    "text_color",
    "text_highlight",
    "cursor",
    
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
    "builtin",

    "error",
    "warning",
    "success",
})

VALID_VALUES_PER_NAME = {
    
    # [license]

    "product_key": "isalpha",

    # [editor]

    "ui_font": "isalpha",
    "ui_font_weight": ["light", "normal", "medium", "bold"],
    "ui_font_size": "int",

    "font": "isalpha",
    "font_weight": ["light", "normal", "medium", "bold"],
    "font_size": "int",

    "cursor_style": ["line", "block"],
    "whitespace_visible": ["always", "onselect"],
    "editor_line_height": ["compact", "comfortable"],
    
    "tab_width": "int",
    "caret_blink_period": "int",

    "window_opacity": "float",
    "ui_opacity": "float",

    "theme": "isalpha",
    "adaptive_theme": "list",

    # "file_explorer_root": "isalpha",

    "file_explorer_as_sidebar": ["left", "right"],
    "outline_panel_as_sidebar": ["left", "right"],

    "terminal_to_use": "isalpha",
    # "path_to_shell": "isalpha",
    # "path_to_playlist": "isalpha",

    "vertical_rulers": "list",

    # -- toggles

    "ai_features_enabled": "bool",
    
    "show_line_numbers": "bool",
    "show_fold_margin": "bool",
    "show_scrollbar": "bool",
    "show_indent_guides": "bool",
    "show_now_playing": "bool",

    "blinking_cursor": "bool",
    "highlight_current_line": "bool",
    "eol_symbols_visible": "bool",
    "open_on_largest_screen": "bool",
    "autocomplete": "bool",
    "auto_indent": "bool",
    "replace_tabs_with_spaces": "bool",

    "wrap_word": "bool",
    "auto_close_tags": "bool",
    "highlight_line_on_jump": "bool",

    "copy_line_if_no_selection": "bool",
    "cut_line_if_no_selection": "bool",

    "use_buffer_switcher": "bool",

    # -- symbols

    # "unsaved_symbol": "isalpha",
    "whitespace_symbol": 1,
    "chat_start_symbol": 2,
    "command_start_symbol": 2,
    
    # -- advanced

    "auto_hide_fold_buttons": ["noncurrent", "never"],
    "eol_mode": ["crlf", "cr", "lf"],

    "cursor_width": "int",
    "caret_extra_height": "int",
    "scrollbar_width": "int",
    "whitespace_opacity": "float",
    "indent_guides_opacity": "float",
    "fade_scrollbar": "int",
    "fade_split_handle": "int",
    
    "auto_close_single_quote": "bool",
    "auto_close_double_quote": "bool",
    "auto_close_square_bracket": "bool",
    "auto_close_curly_bracket": "bool",
    "auto_close_parentheses": "bool",

    # -- status bar

    "show_line_info": "bool",
    "show_path_to_project": "bool",
    "show_path_to_pos": "bool",
    "show_active_lexer": "bool",
    "show_model_status": "bool",

    # [models]

    "code_completion": "list",
    "code_instruction": "list",
    "chat": "list",
}

cdef int is_int(str text):
    try:
        int(text)
        return True
    except ValueError:
        return False

cdef int is_float(str text):
    try:
        float(text)
        return True
    except ValueError:
        return False

cdef int is_bool(str text):
    text = text.lower()
    return text == "true" or text == "false"


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


# cdef int handle_string(int current_char_index, str text, list tokens):
#     cdef int start_pos = current_char_index
#     cdef str quote = text[current_char_index]
#     cdef str lexeme = quote
#     current_char_index += 1

#     while current_char_index < len(text) and text[current_char_index] != quote and text[current_char_index] != '\n':
#         lexeme += text[current_char_index]
#         current_char_index += 1

#     if current_char_index < len(text) and text[current_char_index] == quote:
#         lexeme += text[current_char_index]
#         current_char_index += 1

#     tokens.append((STRING, start_pos, lexeme))
#     return current_char_index


# cdef int handle_number(int current_char_index, str text, list tokens):
#     cdef int start_pos = current_char_index
#     cdef str lexeme = ""

#     while current_char_index < len(text) and (text[current_char_index].isdigit() or text[current_char_index] == '.'):
#         lexeme += text[current_char_index]
#         current_char_index += 1

#     tokens.append((NUMBER, start_pos, lexeme))
#     return current_char_index


cdef int handle_identifier(int current_char_index, str text, list tokens):
    cdef int text_length = len(text)
    cdef int char_index = current_char_index
    cdef int start_pos = current_char_index
    cdef str lexeme

    # LHS

    while char_index < text_length and (text[char_index].isalnum() or text[char_index] == '_'):
        char_index += 1

    lexeme = text[start_pos:char_index]

    if lexeme in ACCEPTED_NAMES:
        tokens.append((DEFAULT, start_pos, lexeme))
    else:
        tokens.append((ERROR, start_pos, lexeme))

    # skip whitespace between LHS and RHS
    while char_index < text_length and (text[char_index] == ' ' or text[char_index] == '\t'):
        char_index += 1

    cdef int rhs_start = char_index
    cdef int comment_pos = -1

    # find comment pos
    while char_index < text_length and text[char_index] not in ('\r', '\n'):
        if text[char_index] == '-' and char_index + 1 < text_length and text[char_index + 1] == '-':
            comment_pos = char_index
            break
        
        char_index += 1

    cdef int rhs_end = comment_pos if comment_pos != -1 else char_index
    cdef str rhs_raw = text[rhs_start:rhs_end]

    # RHS

    cdef str rhs = text[rhs_start:char_index].rstrip()
    if rhs.endswith(','):
        rhs = rhs[:-1].rstrip()

    cdef int rhs_offset_rel = 0
    cdef int rhs_len = len(rhs_raw)

    cdef int item_s
    cdef int item_e
    cdef int trimmed_end_rel
    cdef str item_text
    cdef int abs_item_start

    # handle RHS values

    while rhs_offset_rel < rhs_len:
        
        # skip leading whitespace
        while rhs_offset_rel < rhs_len and (rhs_raw[rhs_offset_rel] == ' ' or rhs_raw[rhs_offset_rel] == '\t'):
            rhs_offset_rel += 1
        
        item_s = rhs_offset_rel

        # scan to comma or EOL
        # while rhs_offset_rel < rhs_len and rhs_raw[rhs_offset_rel] != ',':
        #     rhs_offset_rel += 1
        while rhs_offset_rel < rhs_len:
            rhs_offset_rel += 1
        
        item_e = rhs_offset_rel

        # trim trailing whitespace
        trimmed_end_rel = item_e - 1
        while trimmed_end_rel >= item_s and (rhs_raw[trimmed_end_rel] == ' ' or rhs_raw[trimmed_end_rel] == '\t'):
            trimmed_end_rel -= 1
        
        trimmed_end_rel += 1

        if trimmed_end_rel > item_s:
            item_text = rhs_raw[item_s:trimmed_end_rel]
            abs_item_start = rhs_start + item_s

            if item_text.startswith('"'):
                tokens.append((STRING, abs_item_start, item_text))
            else:
                if lexeme in VALID_VALUES_PER_NAME.keys():
                    valid_values = VALID_VALUES_PER_NAME[lexeme]

                    # list of strings
                    if isinstance(valid_values, list):
                        if item_text in valid_values:
                            tokens.append((STRING, abs_item_start, item_text))
                        else:
                            tokens.append((ERROR, abs_item_start, item_text))

                    # int
                    elif valid_values == "int":
                        if is_int(item_text):
                            tokens.append((NUMBER, abs_item_start, item_text))
                        else:
                            tokens.append((ERROR, abs_item_start, item_text))

                    # list
                    elif valid_values == "list":
                        if "," in item_text:
                            tokens.append((STRING, abs_item_start, item_text))
                        else:
                            tokens.append((ERROR, abs_item_start, item_text))

                    # float
                    elif valid_values == "float":
                        if is_float(item_text):
                            tokens.append((NUMBER, abs_item_start, item_text))
                        else:
                            tokens.append((ERROR, abs_item_start, item_text))

                    # bool
                    elif valid_values == "bool":
                        if is_bool(item_text):
                            tokens.append((NUMBER, abs_item_start, item_text))
                        else:
                            tokens.append((ERROR, abs_item_start, item_text))

                    # isalpha
                    elif valid_values == "isalpha":
                        if item_text.isalpha():
                            tokens.append((STRING, abs_item_start, item_text))
                        else:
                            tokens.append((ERROR, abs_item_start, item_text))

                    # length var
                    elif isinstance(valid_values, int):
                        if len(item_text) <= valid_values:
                            tokens.append((STRING, abs_item_start, item_text))
                        else:
                            tokens.append((ERROR, abs_item_start, item_text))
                    
                    # wildcard (valid name but unknown input)
                    else:
                        tokens.append((STRING, abs_item_start, item_text))
                
                # if not in valid names
                else:
                    tokens.append((COMMENT, abs_item_start, item_text))

        # if there is a comma, emit it with exact absolute position
        if rhs_offset_rel < rhs_len and rhs_raw[rhs_offset_rel] == ',':
            tokens.append((DEFAULT, rhs_start + rhs_offset_rel, ","))
            rhs_offset_rel += 1

    return char_index


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

    def _is_class(self, line_text):
        stripped = line_text.strip()
        return stripped.startswith("[") and "]" in stripped

    def _is_function_name(self, line_text):
        return False

    def _is_type_def(self, line_text):
        return False

    def tokenize(self, str text):
        cdef int current_char_index = 0
        cdef str current_char
        cdef str next_char
        cdef list tokens = []

        while current_char_index < len(text):
            current_char = text[current_char_index]
            next_char = text[current_char_index + 1] if current_char_index + 1 < len(text) else ""

            # whitespace
            if current_char in { ' ', '\t', '\r', '\n' }:
                current_char_index = handle_whitespace(current_char_index)
            
            # comment
            elif current_char == '-' and next_char == '-':
                current_char_index = handle_comment(current_char_index, text, tokens)
            
            # header
            elif current_char == '[':
                current_char_index = handle_header(current_char_index, text, tokens)
            
            # # string
            # elif current_char in { '\"', '\'' }:
            #     current_char_index = handle_string(current_char_index, text, tokens)
            
            # # number
            # elif '0' <= current_char <= '9':
            #     current_char_index = handle_number(current_char_index, text, tokens)
            
            # # symbols
            # elif current_char in { '(', ')', ',' }:
            #     tokens.append((COMMENT, current_char_index, current_char))
            #     current_char_index += 1

            # identifier
            elif current_char.isalpha() or current_char == '_':
                current_char_index = handle_identifier(current_char_index, text, tokens)
            
            # unknown
            else:
                tokens.append((ERROR, current_char_index, current_char))
                current_char_index += 1

        return tokens

