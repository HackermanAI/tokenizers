
# main.py (in same dir as .so)
from todo import Lexer

TEXT = """
# my todo example

* important
- list item
    + another list item

comment
"""

lexer = Lexer()
tokens = lexer.tokenize(TEXT)

for token in tokens: print(token)
# ('keyword', 1, '# my todo example')
# ('error', 20, '* important')
# ('name', 32, '- list item')
# ('success', 48, '+ another list item')
# ('comment', 69, 'c')
# ('comment', 70, 'o')
# ('comment', 71, 'm')
# ('comment', 72, 'm')
# ('comment', 73, 'e')
# ('comment', 74, 'n')
# ('comment', 75, 't')
