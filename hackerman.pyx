
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

# Tokenizer for Hackerman DSCL

# cython: language_level=3
cimport cython
import os

cdef str WHITESPACE = "whitespace"
cdef str DEFAULT = "default"
cdef str KEYWORD = "keyword"
cdef str CLASS = "class"
cdef str NAME = "name"
cdef str STRING = "string"
cdef str NUMBER = "number"
cdef str COMMENT = "comment"

# system colors
cdef str ERROR = "_error"

ACCEPTED_NAMES = frozenset({

    # [license]

    "path_to_license_file",

    # [editor]

    "font",
    "font_weight",
    "font_size",
    "font_ligatures",
    
    "line_height",
    "tab_width",
    
    "theme",
    "adaptive_theme",
    
    "auto_indent",
    
    "auto_close_single_quote",
    "auto_close_double_quote",
    "auto_close_square_bracket",
    "auto_close_curly_bracket",
    "auto_close_parentheses",

    # -- ui

    "show_line_numbers",
    "show_scrollbar",
    "show_indent_guides",
    "show_inline_hints",
    "show_auto_complete",
    "show_minimap",

    "scrollbar_width",
    "indent_guides_opacity",

    # -- cursor

    "cursor_width",
    "cursor_extra_height",
    
    "cursor_as_block",
    "cursor_line_highlight",
    
    "cursor_blink",
    "cursor_blink_period",
    
    "cursor_neon_effect",
    
    # -- sidebar

    "show_sidebar",
    "sidebar_position",

    "file_explorer_root",
    "file_types_to_exclude",

    # -- statusbar

    "show_line_info",
    "show_path_to_project",
    "show_active_lexer",
    "show_model_status",

    # -- misc

    "ai_enabled",
    
    "window_opacity",
    "ui_opacity",

    "ui_font",
    "ui_font_weight",
    "ui_font_size",

    "copy_line_if_no_selection",
    "cut_line_if_no_selection",

    "open_on_largest_screen",
    "replace_tabs_with_spaces",
    "file_to_open_on_startup",

    "inline_command_in_files",
    "inline_command_symbol",

    "eol_mode",
    "eol_symbols_visible",

    "terminal_to_use",
    "path_to_shell",

    "whitespace_symbol",
    "whitespace_opacity",

    "unsaved_symbol", 
    
    "vertical_rulers",

    # -- experimental

    "wrap_word",
    "auto_close_tags",
    "highlight_line_on_jump",
    "tabs_over_spaces",

    # [models]
    
    "code_completion",
    "code_instruction",
    "chat",

    # [keybinds]

    "save_file",
    "save_file_as",
    "new_file",
    "new_window",
    "open_file",
    "fold_line",
    "fold_all",
    "code_instruction",
    "line_comment",
    "line_comment_strict",
    "open_config_file",
    "open_scripts_file",
    "zoom_in",
    "zoom_out",
    "toggle_split_editor",
    "show_file_explorer",
    "show_outline_panel",
    "show_function_explorer",
    "open_terminal_at_file",
    "reveal_in_finder",
    
    "select_all",
    "undo",
    "redo",
    "lowercase",
    "uppercase",
    "cancel",
    "newline",
    "newline_at_end_of_line",
    "tab",
    "backtab",
    "center_on_cursor",
    "line_indent",
    "line_unindent",
    "selection_duplicate",
    "move_line_up",
    "move_line_down",
    
    "open_file_in_new_window",
    "copy_path_to_file",
    "toggle_sidebar",
    "reset_window_pos",
    "system_toggle_dark_mode",
    "toggle_read_only",
    "toggle_newspaper_scroll",
    "select_matches",
    "show_license_info",
    
    "tab_width_2_spaces",
    "tab_width_4_spaces",
    
    "indent_with_spaces",
    "indent_with_tabs",
    
    "find_in_file",
    "show_search_explorer",
    
    "close_file",
    "close_other_files",
    
    "accept_autocomplete",
    "command_chat_complete",
    "move_to_prev_pos",
    
    # -- Native MacOS keys bindings

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

    # -- pane navigation
    
    "focus_main_editor",
    "focus_split_editor",
    "previous_tab",
    "next_tab",
    
    # -- shortcuts to switch tab

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
    "text_color",
    "cursor",
    
    "default",
    "keyword",
    "class",
    "name",
    "lambda",
    "string",
    "number",
    "operator",
    "comment",
    "special",
    "type",
    "boolean",
    "builtin",

    "_error",
    "_warning",
    "_success",

    "_selection",
    "_highlight",
    
    "_title_bar",
    "_status_bar",
})

VALID_VALUES_PER_NAME = {
    
    # [license]

    "path_to_license_file": "path",

    # [editor]

    "font": "name",
    "font_weight": ["light", "normal", "medium", "bold"],
    "font_size": "int",
    "font_ligatures": "bool",

    "line_height": ["compact", "comfortable"],
    "tab_width": "int",

    "theme": "name",
    "adaptive_theme": "list",

    "auto_indent": "bool",
    
    "auto_close_single_quote": "bool",
    "auto_close_double_quote": "bool",
    "auto_close_square_bracket": "bool",
    "auto_close_curly_bracket": "bool",
    "auto_close_parentheses": "bool",

    # -- ui

    "show_line_numbers": "bool",
    "show_scrollbar": "bool",
    "show_indent_guides": "bool",
    "show_inline_hints": "bool",
    "show_auto_complete": "bool",
    "show_minimap": "bool",

    "scrollbar_width": "int",
    "indent_guides_opacity": "float",

    # -- cursor

    "cursor_width": "int",
    "cursor_extra_height": "int",
    
    "cursor_as_block": "bool",
    "cursor_line_highlight": "bool",

    "cursor_blink": "bool",
    "cursor_blink_period": "int",
    
    "cursor_neon_effect": "bool",

    # -- sidebar

    "show_sidebar": "bool",
    "sidebar_position": ["left", "right"],

    "file_explorer_root": "path",
    "file_types_to_exclude": "list",

    # -- statusbar

    "show_line_info": "bool",
    "show_path_to_project": "bool",
    "show_active_lexer": "bool",
    "show_model_status": "bool",

    # -- misc

    "ai_enabled": "bool",

    "window_opacity": "float",
    "ui_opacity": "float",

    "ui_font": "name",
    "ui_font_weight": ["light", "normal", "medium", "bold"],
    "ui_font_size": "int",

    "copy_line_if_no_selection": "bool",
    "cut_line_if_no_selection": "bool",

    "open_on_largest_screen": "bool",
    "replace_tabs_with_spaces": "bool",
    "file_to_open_on_startup": "path",

    "inline_command_in_files": "list",
    "inline_command_symbol": 2, # max length

    "eol_mode": ["crlf", "cr", "lf"],
    "eol_symbols_visible": "bool",

    "terminal_to_use": "name",
    "path_to_shell": "path",

    "whitespace_symbol": 1,
    "whitespace_opacity": "float",
    
    "unsaved_symbol": 12, # max length

    "vertical_rulers": "list",

    # -- experimental

    "wrap_word": "list",
    "auto_close_tags": "bool",
    "highlight_line_on_jump": "bool",
    "tabs_over_spaces": "bool",

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

cdef int is_path(str text):
    cdef str s
    
    if text is None:
        return False
    
    s = text.strip()
    
    if not s:
        return False
    
    # guard for quoted strings
    if len(s) >= 2 and ((s[0] == '"' and s[-1] == '"') or (s[0] == "'" and s[-1] == "'")):
        s = s[1:-1].strip()

    s = os.path.expanduser(os.path.expandvars(s))

    try:
        return os.path.exists(s)
    except Exception:
        return False

cdef int is_name(str text):
    cdef str s
    
    s = (text or "").strip()
    if not s:
        return False

    allowed_extra = set(" -_+.'&()")

    return (
        any(ch.isalnum() for ch in s) and
        all(ch.isalnum() or ch.isspace() or ch in allowed_extra for ch in s)
    )


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


cdef int handle_identifier(int current_char_index, str text, list tokens):
    cdef int text_length = len(text)
    cdef int char_index = current_char_index
    cdef int start_pos = current_char_index
    cdef str lexeme

    # LHS

    while char_index < text_length and (text[char_index].isalnum() or text[char_index] == '_'):
        char_index += 1

    lexeme = text[start_pos:char_index]

    if lexeme in ACCEPTED_NAMES or lexeme in VALID_VALUES_PER_NAME.keys():
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
                            
                    # name
                    elif valid_values == "name":
                        if is_name(item_text):
                            tokens.append((STRING, abs_item_start, item_text))
                        else:
                            tokens.append((ERROR, abs_item_start, item_text))
                            
                    # path
                    elif valid_values == "path":
                        if is_path(item_text):
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


cdef class Lexer:
    cdef public object cmd_start
    cdef public object cmd_end

    cdef readonly str lexer_name
    cdef readonly str comment_char
    cdef readonly str line_comment

    def __cinit__(self, cmd_start=None, cmd_end=None):
        self.cmd_start = cmd_start
        self.cmd_end = cmd_end
        
        self.lexer_name = u"Hackerman Config"
        self.comment_char = u"--"
        self.line_comment = u"--"

    def colors(self):
        return (DEFAULT, KEYWORD, CLASS, NAME, STRING, NUMBER, COMMENT)

    # for outline panel

    def _is_class(self, str line_text):
        cdef str stripped = line_text.strip()

        if not stripped.startswith("["):
            return False

        return [("keyword", stripped)]

    cpdef bint _is_function_name(self, str line_text):
        return False

    cpdef bint _is_type_def(self, str line_text):
        return False

    # tokenizer

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

            # identifier
            elif current_char.isalpha() or current_char == '_':
                current_char_index = handle_identifier(current_char_index, text, tokens)
            
            # unknown
            else:
                tokens.append((ERROR, current_char_index, current_char))
                current_char_index += 1

        return tokens

