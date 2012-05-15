log = ->
  console.log.apply(console, arguments)

F.Lexer = class Lexer

  # Token-matching RegExps
  @tokenRegex:
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
  @tokenPriority: [
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

  @blacklistedTokens: [ 'WHITESPACE' ]

  @whitespaceChar: /\ufeff/

  # Main function of the `Lexer` which returns a `Array` of tokens
  @tokenize: (chunk) ->
    # Starting offset within the RegExp-string for the current chunk
    startOffset = 0

    # `Array` of collected tokens
    tokens = []

    # Next selection boundary index
    nextSelectionIndex = null

    # Iterate of the remaining regexp string until its all gone
    while chunk

      # Get the next selection index in the chunk
      if nextSelectionIndex isnt -1 and nextSelectionIndex <= startOffset
        chunk = chunk.replace Lexer.whitespaceChar, (match, parts..., offset, str) ->
          nextSelectionIndex = offset
          ""
        log chunk

      # For each token-kind...
      for tokenKind in Lexer.tokenPriority

        # ...try matching the RegExp-string (from the beginning of the string)
        unless match = Lexer.tokenRegex[tokenKind].exec chunk
          # Move on to the next token
          continue

        # Break out the matched text from the regex
        [matchedText] = match

        # Get the end offset of the match
        endOffset = startOffset + matchedText.length
        tokenContainsSelection = false
        tokenSelectionIndex = -1

        # If the selection boundary is within the match keep the offset within
        if startOffset <= nextSelectionIndex <= endOffset
          tokenContainsSelection = true
          tokenSelectionIndex = nextSelectionIndex - startOffset

        # Advance the start offset for the next match
        startOffset = endOffset

        # Move the regexp string forward
        chunk = chunk[matchedText.length..]

        # Add the new token to the token stream if its not blacklisted
        if tokenKind not in Lexer.blacklistedTokens
          if tokenContainsSelection
            log tokenKind, matchedText, tokenSelectionIndex
          tokens.push [tokenKind, matchedText, tokenContainsSelection, tokenSelectionIndex]

        # Stop searching
        break

    # Return the tokens
    return tokens
