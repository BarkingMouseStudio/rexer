F.Lexer = class Lexer

  # Token-matching RegExps
  @token_regex:
    SELECTION_BOUNDARY: /^\ufeff/
    SPECIAL_CHAR: /^\\[wWdDsSbB]/
    WHITESPACE_CHAR: /^\\[tnr]/
    ESCAPED_CHAR: /^\\./
    INPUT_START: /^\^/
    INPUT_END: /^\$/
    ESCAPED_DOLLAR: /^\${2}/
    QUANTIFIER: /^(?:(\?)|([\+\*]\??))/
    GROUP_START: /^\((\?(?:(?:\:)|(?:\=)|(?:\!)|(?:\<\=)|(?:\<\!))?)?/
    GROUP_END: /^\)/
    OR: /^\|/
    RANGE: /^\{(?:(\d*,\d+)|(\d+,\d*))\}/
    CHAR_GROUP: /^(\[\^?)((?:\\\]|.)+?)\]/
    OTHER: /^[^\#\(\)\|\[\]\?\+\*\^\$\\\s*]+/
    WHITESPACE: /^\s+/
    COMMENT: /^\ \#\ (.*)\s*$/m

  # Controls the tokenization priority
  @token_priority: [
    'WHITESPACE'
    'SPECIAL_CHAR'
    'WHITESPACE_CHAR'
    'ESCAPED_CHAR'
    'INPUT_START'
    'ESCAPED_DOLLAR'
    'INPUT_END'
    'QUANTIFIER'
    'GROUP_START'
    'GROUP_END'
    'OR'
    'RANGE'
    'CHAR_GROUP'
    'COMMENT'
    'OTHER'
  ]

  @blacklisted_tokens: [
    'WHITESPACE'
  ]

  # Main function of the `Lexer` which returns a `Array` of tokens
  @tokenize: (regexpStr) ->
    # Maintain an index within the RegExp-string
    i = 0

    # The token
    tokens = []

    # Maintain the next selection boundary index...
    nextSelectionIndex = -1

    # ...and whether the token contains a selection boundary
    tokenContainsSelection = false

    # Create chunks by slicing the string from the current index to the end
    while chunk = regexpStr[i..]
      if nextSelectionIndex < i
        nextSelectionIndex = chunk.indexOf(Lexer.token_regex['SELECTION_BOUNDARY'])
        chunk.replace(Lexer.token_regex['SELECTION_BOUNDARY'], '')

      # For each token-kind...
      for token_kind in Lexer.token_priority
        # ...try matching the RegExp-string (from the beginning of the string)
        unless match = Lexer.token_regex[token_kind].exec chunk
          # Move on to the next token
          continue

        # If a match is found:
        # Break out the matched text from the regex
        [matched_text] = match

        # Move `i` (the current index) forward by the match's length
        i += matched_text.length

        # Add the new token to the token stream if its not blacklisted
        if token_kind not in Lexer.blacklisted_tokens
          tokens.push [token_kind, matched_text]

        break

    # Return the tokens
    return tokens
