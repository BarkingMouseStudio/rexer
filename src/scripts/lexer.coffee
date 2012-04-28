F.Lexer = class Lexer
  @tokens:
    SELECTION_BOUNDARY: /^\ufeff/
    BACKSLASH: /^\\(?:([tnr])|([wWdDsSbB])|(.))?/
    INPUT_START: /^\^/
    INPUT_END: /^\$/
    ESCAPED_DOLLAR: /^\${2}/
    QUANTIFIER: /^(?:(\?)|([\+\*]\??))/
    GROUP_START: /^\((\?(?:(?:\:)|(?:\=)|(?:\!)|(?:\<\=)|(?:\<\!))?)?/
    GROUP_END: /^\)/
    OR: /^\|/
    RANGE: /^\{(?:(\d*,\d+)|(\d+,\d*))\}/
    CHAR_GROUP: /^(\[\^?)((?:\\\]|.)+?)\]/
    OTHER: /^[^\(\)\|\[\]\?\+\*\^\$\\\ufeff]+/
    COMMENT: /^#\s*(.*?)\s*$/

  @tokenize: (regexpStr) ->
    i = 0
    tokens = []

    while chunk = regexpStr[i..]
      if match = Lexer.tokens.SELECTION_BOUNDARY.exec chunk
        [matched_text] = match
        i += matched_text.length
        tokens.push ['SELECTION_BOUNDARY', matched_text]
      else if match = Lexer.tokens.BACKSLASH.exec chunk
        [matched_text, whitespace, identifier, escaped] = match
        i += matched_text.length

        if identifier
          tokens.push ['SPECIAL', matched_text]
        else if whitespace
          tokens.push ['WHITESPACE', matched_text]
        else
          tokens.push ['ESCAPED', matched_text]
      else if match = Lexer.tokens.INPUT_START.exec chunk
        [matched_text] = match
        i += matched_text.length
        tokens.push ['INPUT_START', matched_text]
      else if match = Lexer.tokens.ESCAPED_DOLLAR.exec chunk
        [matched_text] = match
        i += matched_text.length
        tokens.push ['ESCAPED_DOLLAR', matched_text]
      else if match = Lexer.tokens.INPUT_END.exec chunk
        [matched_text] = match
        i += matched_text.length
        tokens.push ['INPUT_END', matched_text]
      else if match = Lexer.tokens.QUANTIFIER.exec chunk
        [matched_text, optional, counter] = match
        i += matched_text.length
        tokens.push ['QUANTIFIER', matched_text]
      else if match = Lexer.tokens.GROUP_START.exec chunk
        [matched_text] = match
        i += matched_text.length
        tokens.push ['GROUP_START', matched_text]
      else if match = Lexer.tokens.GROUP_END.exec chunk
        [matched_text] = match
        i += matched_text.length
        tokens.push ['GROUP_END', matched_text]
      else if match = Lexer.tokens.OR.exec chunk
        [matched_text] = match
        i += matched_text.length
        tokens.push ['OR', matched_text]
      else if match = Lexer.tokens.RANGE.exec chunk
        [matched_text] = match
        i += matched_text.length
        tokens.push ['RANGE', matched_text]
      else if match = Lexer.tokens.CHAR_GROUP.exec chunk
        [matched_text, start, characters] = match
        i += matched_text.length
        tokens.push ['CHAR_GROUP_START', start]
        tokens.push ['CHAR_GROUP', characters]
        tokens.push ['CHAR_GROUP_END', ']']
      else if match = Lexer.tokens.COMMENT.exec chunk
        [matched_text, comment] = match
        i += matched_text.length
        tokens.push ['COMMENT', comment]
      else if match = Lexer.tokens.OTHER.exec chunk
        [matched_text] = match
        i += matched_text.length
        tokens.push ['', matched_text]

    return tokens
