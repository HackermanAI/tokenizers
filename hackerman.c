
// gcc -shared -o libhackerman.dylib -fPIC hackerman.c

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

#define MAX_NAME_COUNT 100

const char *NAME[] = {
    "font", "font_weight", "font_size", "tab_width", "cursor_width",
    "margin", "theme", "file_explorer_root", "model_to_use", "eol_mode",
    "show_line_numbers", "transparent", "blockcursor", "wrap_word",
    "blinking_cursor", "show_scrollbar", "show_minimap", "highlight_todos",
    "whitespace_visible", "indent_guides", "highlight_current_line",
    "highlight_current_line_on_jump", "show_eol"
};
size_t NAME_COUNT = sizeof(NAME) / sizeof(NAME[0]);

bool is_name(const char *value) {
    for (size_t i = 0; i < NAME_COUNT; i++) {
        if (strcmp(NAME[i], value) == 0) {
            return true;
        }
    }
    return false;
}

bool is_conditional(const char *value) {
    return strcmp(value, "true") == 0 || strcmp(value, "false") == 0;
}

char *tokenize(const char *text) {
    // size_t buffer_size = 4096;
    size_t buffer_size = strlen(text) * 4;
    size_t index = 0;
    size_t result_index = 0;
    
    char *result = malloc(buffer_size);
    if (!result) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }

    while (text[index] != '\0') {        
        // skip whitespace
        if (isspace(text[index])) {
            index++;
            continue;
        }

        // comment
        if (text[index] == '-') {
            if (text[index + 1] == '-') {
                result_index += snprintf(result + result_index, buffer_size - result_index, "TYPE=COMMENT START=%zu VALUE=-- ", index);
                index += 2;
                while (text[index] != '\0' && text[index] != '\n') {
                    result_index += snprintf(result + result_index, buffer_size - result_index, "%c", text[index]);
                    index++;
                }
            } else {
                result_index += snprintf(result + result_index, buffer_size - result_index, "TYPE=ERROR START=%zu VALUE=- ", index);
                index++;
            }
            continue;
        }

        // header
        if (text[index] == '[') {
            size_t start_pos = index;
            result_index += snprintf(result + result_index, buffer_size - result_index, "TYPE=KEYWORD START=%zu VALUE=[", start_pos);
            index++;
            while (text[index] != '\0' && text[index] != ']') {
                result_index += snprintf(result + result_index, buffer_size - result_index, "%c", text[index]);
                index++;
            }
            if (text[index] == ']') {
                result_index += snprintf(result + result_index, buffer_size - result_index, "] ");
                index++;
            }
            continue;
        }

        // string
        if (text[index] == '"' || text[index] == '\'') {
            size_t start_pos = index;
            char quote = text[index];
            result_index += snprintf(result + result_index, buffer_size - result_index, "TYPE=STRING START=%zu VALUE=", start_pos);
            result_index += snprintf(result + result_index, buffer_size - result_index, "%c", quote);
            index++;
            while (text[index] != '\0' && text[index] != quote) {
                result_index += snprintf(result + result_index, buffer_size - result_index, "%c", text[index]);
                index++;
            }
            if (text[index] == quote) {
                result_index += snprintf(result + result_index, buffer_size - result_index, "%c ", quote);
                index++;
            }
            continue;
        }

        // number
        if (isdigit(text[index])) {
            size_t start_pos = index;
            result_index += snprintf(result + result_index, buffer_size - result_index, "TYPE=NUMBER START=%zu VALUE=", start_pos);
            while (isdigit(text[index])) {
                result_index += snprintf(result + result_index, buffer_size - result_index, "%c", text[index]);
                index++;
            }
            result_index += snprintf(result + result_index, buffer_size - result_index, " ");
            continue;
        }

        if (isalpha(text[index]) || text[index] == '_') {
            size_t start_pos = index;
            char buffer[128];
            size_t length = 0;

            while (isalnum(text[index]) || text[index] == '_') {
                buffer[length++] = text[index];
                index++;
            }
            buffer[length] = '\0';

            if (is_conditional(buffer)) {
                result_index += snprintf(result + result_index, buffer_size - result_index, "TYPE=CONDITIONAL START=%zu VALUE=%s ", start_pos, buffer);
            } else if (is_name(buffer)) {
                result_index += snprintf(result + result_index, buffer_size - result_index, "TYPE=NAME START=%zu VALUE=%s ", start_pos, buffer);
            } else {
                result_index += snprintf(result + result_index, buffer_size - result_index, "TYPE=IDENTIFIER START=%zu VALUE=%s ", start_pos, buffer);
            }
            continue;
        }

        result_index += snprintf(result + result_index, buffer_size - result_index, "TYPE=DEFAULT START=%zu VALUE=%c ", index, text[index]);
        index++;
    }

    result[result_index] = '\0';
    return result;
}

void free_memory(char *ptr) {
    if (ptr) {
        free(ptr);
        ptr = NULL;
    }
}

