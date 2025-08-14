
# Tokenizer wrapper for Odin

from . import odin_tokenizer as _odin

class Lexer:

    KIND = _odin.KIND
    kind_name = staticmethod(_odin.kind_name)
    
    @property
    def lexer_name(self) -> str:
        return "Odin"

    @property
    def comment_char(self) -> str:
        return "//"

    def tokenize(self, text):
        data = text.encode("utf-8") if isinstance(text, str) else text
        return _odin.tokenize(data)


