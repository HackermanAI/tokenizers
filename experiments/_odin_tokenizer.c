
// Tokenizer for Odin
// MIT © 2025 @asyncze (Michael Sjöberg)
// Build:
// export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
// clang -O3 -fPIC -shared -std=c11 -undefined dynamic_lookup $(python3-config --includes) odin_tokenizer.c -o odin_tokenizer$(python3-config --extension-suffix)

#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

// --- Token Types ---

typedef enum {
    TK_DEFAULT = 0,
    TK_KEYWORD,
    TK_CLASS,       // (unused here)
    TK_NAME,        // (unused here)
    TK_PARAMETER,   // (unused here)
    TK_LAMBDA,      // (unused here)
    TK_STRING,
    TK_NUMBER,
    TK_OPERATOR,
    TK_COMMENT,
    TK_SPECIAL,     // (unused here)
    TK_TYPE,
    TK_CONDITIONAL,
    TK_BUILT_IN,
    TK_ERROR,
    TK_WARNING,     // (unused here)
    TK_SUCCESS,     // (unused here)
} TokenKind;

typedef struct {
    int kind;
    Py_ssize_t start;
    Py_ssize_t len;
} Token;

typedef struct {
    Token* data;
    Py_ssize_t count;
    Py_ssize_t cap;
} TokenBuf;

static int tokbuf_grow(TokenBuf* tb) {
    Py_ssize_t newcap = tb->cap ? tb->cap * 2 : 1024;
    void* p = realloc(tb->data, newcap * sizeof(Token));
    if (!p) return 0;
    tb->data = (Token*)p; tb->cap = newcap; return 1;
}
static int tokbuf_push(TokenBuf* tb, int kind, Py_ssize_t start, Py_ssize_t len) {
    if (tb->count == tb->cap && !tokbuf_grow(tb)) return 0;
    tb->data[tb->count++] = (Token){kind, start, len};
    return 1;
}

// --- Helpers ---

static inline int is_alpha(uint8_t c) { c|=32; return (c>='a' && c<='z') || c=='_'; }
static inline int is_digit(uint8_t c) { return (c>='0' && c<='9'); }
static inline int is_alnum(uint8_t c) { return is_alpha(c) || is_digit(c); }
static inline int is_space(uint8_t c) { return c==' '||c=='\t'||c=='\r'||c=='\f'||c=='\v'; }

typedef struct { const char* s; uint8_t ln; } Word;

// KEYWORDS
static const Word KEYWORDS[] = {
    {"asm",3},{"auto_cast",9},{"bit_set",7},{"break",5},{"case",4},{"cast",4},
    {"context",7},{"continue",8},{"defer",5},{"distinct",8},{"do",2},{"dynamic",7},
    {"else",4},{"enum",4},{"fallthrough",11},{"for",3},{"foreign",7},{"if",2},
    {"import",6},{"in",2},{"map",3},{"not_in",6},{"or_else",7},{"or_return",9},
    {"package",7},{"proc",4},{"return",6},{"struct",6},{"switch",6},{"transmute",9},
    {"typeid",6},{"union",5},{"using",5},{"when",4},{"where",5},
};
static const int N_KEYWORDS = (int)(sizeof(KEYWORDS)/sizeof(KEYWORDS[0]));

// BUILT_INS
static const Word BUILT_INS[] = {
    {"fmt",3},{"len",3},{"println",7},
};
static const int N_BUILT_INS = (int)(sizeof(BUILT_INS)/sizeof(BUILT_INS[0]));

// TYPES (from your set)
static const Word TYPES[] = {
    {"i8",2},{"i16",3},{"i32",3},{"i64",3},{"i128",4},{"int",3},
    {"u8",2},{"u16",3},{"u32",3},{"u64",3},{"u128",4},{"uint",4},
    {"f32",3},{"f64",3},{"complex64",9},{"complex128",10},
    {"quaternion128",13},{"quaternion256",13},{"string",6},{"rune",4},{"bool",4},
};
static const int N_TYPES = (int)(sizeof(TYPES)/sizeof(TYPES[0]));

// CONDITIONAL literals
static const Word CONDITIONALS[] = { {"true",4}, {"false",5} };
static const int N_CONDITIONALS = 2;

static int word_in_table(const Word* tab, int n, const uint8_t* p, Py_ssize_t ln) {
    if (ln < 1 || ln > 64) return 0;
    uint8_t c0 = p[0] | 32;
    for (int i=0;i<n;i++) {
        if (((tab[i].s[0]|32)==c0) && tab[i].ln==ln && memcmp(tab[i].s, (const char*)p, (size_t)ln)==0)
            return 1;
    }
    return 0;
}

// --- Scanner ---

typedef struct {
    const uint8_t* buf;
    const uint8_t* t;
    const uint8_t* max_t;
} Scanner;

static inline void eat_ws(Scanner* sc) {
    const uint8_t* t=sc->t; const uint8_t* max=sc->max_t;
    while (t<max) {
        if (*t=='\n') break; // newline is its own token
        if (!is_space(*t)) break;
        t++;
    }
    sc->t = t;
}

static void scan_line_comment(Scanner* sc) {
    const uint8_t* t = sc->t; const uint8_t* max=sc->max_t;
    // assumes we are at first '/' of '//'
    t += 2;
    while (t<max && *t!='\n') t++;
    sc->t = t;
}

static void scan_block_comment(Scanner* sc) {
    const uint8_t* t = sc->t; const uint8_t* max=sc->max_t;
    // assumes we are at first '/' of '/*'
    t += 2;
    while (t+1<max) {
        if (t[0]=='*' && t[1]=='/') { t+=2; break; }
        t++;
    }
    sc->t = t;
}

static void scan_string(Scanner* sc, uint8_t delim) {
    const uint8_t* t = sc->t; const uint8_t* max=sc->max_t;
    int raw = (delim=='`');
    t++; // skip opening
    if (raw) {
        while (t<max && *t!=delim) t++;
        if (t<max) t++; // closing
    } else {
        int esc=0;
        while (t<max) {
            uint8_t c=*t;
            if (c=='\n') break;
            if (c==delim && !esc) { t++; break; }
            esc = (!esc && c=='\\');
            t++;
        }
    }
    sc->t = t;
}

static void scan_number(Scanner* sc) {
    const uint8_t* t = sc->t; const uint8_t* max=sc->max_t;
    t++; // first digit consumed
    // very simple: digits and dots; breaks on '..' range
    while (t<max) {
        uint8_t c=*t;
        if (c=='_') { t++; continue; }
        if (c=='.') {
            if ((t+1)<max && t[1]=='.') break; // range op
            t++; continue;
        }
        if (!is_digit(c)) break;
        t++;
    }
    sc->t = t;
}

static void scan_identifier(Scanner* sc) {
    const uint8_t* t = sc->t; const uint8_t* max=sc->max_t;
    t++; while (t<max && (is_alnum(*t) || *t=='_')) t++;
    sc->t = t;
}

static int next_token(Scanner* sc, TokenBuf* out) {
    eat_ws(sc);
    if (sc->t >= sc->max_t) return 0;

    const uint8_t* start = sc->t;
    uint8_t c = *sc->t;

    // newline is its own token (optional—delete if not needed)
    if (c=='\n') {
        sc->t++;
        if (!tokbuf_push(out, TK_DEFAULT, (Py_ssize_t)(start - sc->buf), 1)) return -1;
        return 1;
    }

    // attribute '@name' (letters/underscore/digits/() allowed like your version)
    if (c=='@') {
        sc->t++;
        while (sc->t < sc->max_t) {
            uint8_t d = *sc->t;
            if (!(is_alnum(d) || d=='_' || d=='(' || d==')')) break;
            sc->t++;
        }
        if (!tokbuf_push(out, TK_OPERATOR, (Py_ssize_t)(start - sc->buf), (Py_ssize_t)(sc->t - start))) return -1;
        return 1;
    }

    // directive '#name'
    if (c=='#') {
        sc->t++;
        while (sc->t < sc->max_t) {
            uint8_t d=*sc->t;
            if (!(is_alnum(d) || d=='_')) break;
            sc->t++;
        }
        if (!tokbuf_push(out, TK_KEYWORD, (Py_ssize_t)(start - sc->buf), (Py_ssize_t)(sc->t - start))) return -1;
        return 1;
    }

    // comments
    if (c=='/' && (sc->t+1)<sc->max_t) {
        uint8_t n = sc->t[1];
        if (n=='/') {
            scan_line_comment(sc);
            if (!tokbuf_push(out, TK_COMMENT, (Py_ssize_t)(start - sc->buf), (Py_ssize_t)(sc->t - start))) return -1;
            return 1;
        } else if (n=='*') {
            scan_block_comment(sc);
            if (!tokbuf_push(out, TK_COMMENT, (Py_ssize_t)(start - sc->buf), (Py_ssize_t)(sc->t - start))) return -1;
            return 1;
        }
    }

    // scope '::' and range '..'
    if (c==':' && (sc->t+1)<sc->max_t && sc->t[1]==':') {
        sc->t += 2;
        if (!tokbuf_push(out, TK_KEYWORD, (Py_ssize_t)(start - sc->buf), 2)) return -1;
        return 1;
    }
    if (c=='.' && (sc->t+1)<sc->max_t && sc->t[1]=='.') {
        sc->t += 2;
        if (!tokbuf_push(out, TK_OPERATOR, (Py_ssize_t)(start - sc->buf), 2)) return -1;
        return 1;
    }

    // operators (single char)
    if (strchr("=!^?+-*%&|~<>/:", c) != NULL) {
        sc->t++;
        if (!tokbuf_push(out, TK_OPERATOR, (Py_ssize_t)(start - sc->buf), 1)) return -1;
        return 1;
    }

    // string
    if (c=='\'' || c=='"' || c=='`') {
        scan_string(sc, c);
        // unterminated -> TK_ERROR
        int kind = (sc->t>start && (sc->t[-1]==c || c=='`')) ? TK_STRING : TK_ERROR;
        if (!tokbuf_push(out, kind, (Py_ssize_t)(start - sc->buf), (Py_ssize_t)(sc->t - start))) return -1;
        return 1;
    }

    // number
    if (is_digit(c)) {
        scan_number(sc);
        if (!tokbuf_push(out, TK_NUMBER, (Py_ssize_t)(start - sc->buf), (Py_ssize_t)(sc->t - start))) return -1;
        return 1;
    }

    // identifier / keyword / built_in / type / conditional
    if (is_alpha(c) || c=='_') {
        scan_identifier(sc);
        Py_ssize_t len = (Py_ssize_t)(sc->t - start);
        int kind = TK_DEFAULT;
        if (word_in_table(KEYWORDS, N_KEYWORDS, start, len)) kind = TK_KEYWORD;
        else if (word_in_table(BUILT_INS, N_BUILT_INS, start, len)) kind = TK_BUILT_IN;
        else if (word_in_table(TYPES, N_TYPES, start, len)) kind = TK_TYPE;
        else if (word_in_table(CONDITIONALS, N_CONDITIONALS, start, len)) kind = TK_CONDITIONAL;

        if (!tokbuf_push(out, kind, (Py_ssize_t)(start - sc->buf), len)) return -1;
        return 1;
    }

    // default single char
    sc->t++;
    if (!tokbuf_push(out, TK_DEFAULT, (Py_ssize_t)(start - sc->buf), 1)) return -1;
    return 1;
}

// --- Python binding ---
static PyObject* py_tokenize(PyObject* self, PyObject* args, PyObject* kwargs) {
    // Accept: bytes/bytearray/memoryview (preferred), or str (will encode to UTF-8 once)
    static char* kwlist[] = { "data", NULL };
    PyObject* obj;
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "O", kwlist, &obj)) return NULL;

    Py_buffer view;
    uint8_t* buf = NULL;
    Py_ssize_t n = 0;
    PyObject* temp_bytes = NULL;

    if (PyUnicode_Check(obj)) {
        temp_bytes = PyUnicode_AsEncodedString(obj, "utf-8", "surrogatepass");
        if (!temp_bytes) return NULL;
        if (PyObject_GetBuffer(temp_bytes, &view, PyBUF_SIMPLE) != 0) {
            Py_DECREF(temp_bytes); return NULL;
        }
        buf = (uint8_t*)view.buf; n = view.len;
    } else {
        if (PyObject_GetBuffer(obj, &view, PyBUF_SIMPLE) != 0) return NULL;
        buf = (uint8_t*)view.buf; n = view.len;
    }

    TokenBuf out = {0};
    Scanner sc = { buf, buf, buf + n };
    int rc;
    while ((rc = next_token(&sc, &out)) > 0) { /* loop */ }
    if (rc < 0) {
        if (temp_bytes) { PyBuffer_Release(&view); Py_DECREF(temp_bytes); }
        else PyBuffer_Release(&view);
        free(out.data);
        return PyErr_NoMemory();
    }

    PyObject* pylist = PyList_New(out.count);
    if (!pylist) {
        if (temp_bytes) { PyBuffer_Release(&view); Py_DECREF(temp_bytes); }
        else PyBuffer_Release(&view);
        free(out.data);
        return NULL;
    }
    for (Py_ssize_t i=0;i<out.count;i++) {
        Token* t = &out.data[i];
        // (kind:int, start:int, len:int)
        PyObject* tup = Py_BuildValue("(iii)", t->kind, (int)t->start, (int)t->len);
        if (!tup) { Py_DECREF(pylist); if (temp_bytes){PyBuffer_Release(&view); Py_DECREF(temp_bytes);} else PyBuffer_Release(&view); free(out.data); return NULL; }
        PyList_SET_ITEM(pylist, i, tup);
    }

    if (temp_bytes) { PyBuffer_Release(&view); Py_DECREF(temp_bytes); }
    else PyBuffer_Release(&view);
    free(out.data);
    return pylist;
}

static PyObject* py_kind_name(PyObject* self, PyObject* args) {
    int k;
    if (!PyArg_ParseTuple(args, "i", &k)) return NULL;
    const char* name =
        k==TK_DEFAULT?"default":
        k==TK_KEYWORD?"keyword":
        k==TK_CLASS?"class":
        k==TK_NAME?"name":
        k==TK_PARAMETER?"parameter":
        k==TK_LAMBDA?"lambda":
        k==TK_STRING?"string":
        k==TK_NUMBER?"number":
        k==TK_OPERATOR?"operator":
        k==TK_COMMENT?"comment":
        k==TK_SPECIAL?"special":
        k==TK_TYPE?"type":
        k==TK_CONDITIONAL?"conditional":
        k==TK_BUILT_IN?"built_in":
        k==TK_ERROR?"error":
        k==TK_WARNING?"warning":
        k==TK_SUCCESS?"success":"default";
    return PyUnicode_FromString(name);
}

static PyMethodDef Methods[] = {
    {"tokenize", (PyCFunction)py_tokenize, METH_VARARGS|METH_KEYWORDS, "Tokenize Odin source. Returns list of (kind, start, len)."},
    {"kind_name", py_kind_name, METH_VARARGS, "Map kind int -> name string."},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef moduledef = {
    PyModuleDef_HEAD_INIT,
    "odin_tokenizer",
    "Fast Odin tokenizer (C)",
    -1,
    Methods
};

PyMODINIT_FUNC PyInit_odin_tokenizer(void) {
    PyObject* m = PyModule_Create(&moduledef);
    if (!m) return NULL;

    // Export KIND_NAME dict for convenience
    PyObject* d = PyDict_New();
    if (!d) return m;

    #define PUT(k) PyDict_SetItemString(d, #k, PyLong_FromLong(k))
    PUT(TK_DEFAULT); PUT(TK_KEYWORD); PUT(TK_CLASS); PUT(TK_NAME); PUT(TK_PARAMETER);
    PUT(TK_LAMBDA); PUT(TK_STRING); PUT(TK_NUMBER); PUT(TK_OPERATOR); PUT(TK_COMMENT);
    PUT(TK_SPECIAL); PUT(TK_TYPE); PUT(TK_CONDITIONAL); PUT(TK_BUILT_IN);
    PUT(TK_ERROR); PUT(TK_WARNING); PUT(TK_SUCCESS);
    #undef PUT

    PyModule_AddObject(m, "KIND", d); // owns ref
    return m;
}





