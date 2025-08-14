
# Tokenizer for Python (tree-sitter)

from tree_sitter import Parser#, Query, QueryCursor
from tree_sitter_languages import get_language, get_parser

DEFAULT     = "default"
KEYWORD     = "keyword"
STRING      = "string"
NUMBER      = "number"
OPERATOR    = "operator"
COMMENT     = "comment"
NAME        = "name" # identifiers

_PY_HIGHLIGHTS = r"""
; comments
(comment) @comment

; strings (single, triple, f-strings counted as string)
(string) @string

; numbers
(integer) @number
(float)   @number

; identifiers
(identifier) @identifier

; keywords (anonymous tokens)
((identifier) @keyword
  (#match? @keyword "^(?:False|None|True|and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield|match|case)$"))


; operators / punctuation you may want to color
[
  "+" "-" "*" "**" "/" "//" "%" "@"
  "<<" ">>" "&" "|" "^" "~"
  ":=" "<" ">" "<=" ">=" "==" "!="
  "=" ":" "," "." ";" "->"
  "(" ")" "[" "]" "{" "}"
] @operator
"""

_CAPTURE_TO_TYPE = {
    "comment": COMMENT,
    "string": STRING,
    "number": NUMBER,
    "identifier": NAME,
    "keyword": KEYWORD,
    "operator": OPERATOR,
}

class Lexer:

    def __init__(self):
        lang = get_language("python")
        
        #self._parser = Parser()
        # self._parser.set_language(lang)
        self._parser = get_parser("python")
        
        # self._query = Query(lang, _PY_HIGHLIGHTS)
        # self._cursor = QueryCursor()

        self._query = lang.query(_PY_HIGHLIGHTS)
    
    @property
    def lexer_name(self) -> str:
        return "Python (tree-sitter)"

    @property
    def comment_char(self) -> str:
        return "#"

    def tokenize(self, text):
        """
        Returns [(type, start_byte, lexeme)]
        """
        data = text.encode("utf-8", "surrogatepass") if isinstance(text, str) else bytes(text)
        tree = self._parser.parse(data)

        # tokens = []
        # # Old-style captures: list of (node, capture_name:str)
        # for node, capture_name in self._query.captures(tree.root_node):
        #     typ = _CAPTURE_TO_TYPE.get(capture_name, DEFAULT)
        #     s, e = node.start_byte, node.end_byte
        #     if e > s:
        #         tokens.append((typ, s, data[s:e].decode("utf-8", "surrogatepass")))

        tokens = []
        for node, capture_name in self._query.captures(tree.root_node):
            token_type = _CAPTURE_TO_TYPE.get(capture_name, DEFAULT)
            s, e = node.start_byte, node.end_byte
            if e > s:
                tokens.append((token_type, s, e))
        
        return sorted(tokens, key=lambda t: t[1])

        # tokens.sort(key=lambda t: t[1])
        # return tokens


