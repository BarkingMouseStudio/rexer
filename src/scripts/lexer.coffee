F.Lexer = class Lexer

  # Token-matching RegExps
  @tokenRegex:
    PROLOGUE: /^\/{3}/
    EPILOGUE: /^\/{3}([imgy]{0,4})$/

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
    CHAR_GROUP: /^(\[\^?)((?:(?:[^\\]\\\])|.)+?)\]/
    OTHER: /^[^\#\(\)\|\[\]\?\+\*\^\$\\\s*]+/
    WHITESPACE: /^\s+/
    COMMENT: /^\ \#\ (.*)\s*$/m

  # Controls the tokenization priority
  @tokenPriority: [
    'SPECIAL_CHAR'
    'WHITESPACE_CHAR'
    'ESCAPED_CHAR'
    'WHITESPACE'
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
    'PROLOGUE'
    'EPILOGUE'
    'OTHER'
  ]

  @unicode200B: '\u200b' # zero-width space
  @unicodeFEFF: '\ufeff' # non-breaking zero-width space

  @getIndices: (haystack, needle) ->
    indices = []
    index = -1
    while true
      index = haystack.indexOf(needle, index)
      break if index is -1
      indices.push(index)
      index += needle.length
    return indices

  # Main function of the `Lexer` which returns a `Array` of tokens
  @tokenize: (chunk) ->
    startOffset = 0
    endOffset = -1
    tokens = []

    # Selection boundary indices
    selectionIndices = Lexer.getIndices(chunk, '\ufeff')

    # Remove selection boundaries
    chunk = chunk.replace(/\ufeff+/g, '')
    length = chunk.length

    # Iterate of the remaining regexp string until its all gone
    while chunk

      for tokenKind in Lexer.tokenPriority

        unless match = Lexer.tokenRegex[tokenKind].exec chunk
          continue

        # Prologue only valid at 0
        if tokenKind is 'PROLOGUE' and startOffset isnt 0
          continue

        [matchedText] = match

        endOffset = startOffset + matchedText.length

        tokenSelectionIndices = []
        
        while true
          index = selectionIndices[0]
          console.log startOffset, endOffset, index - startOffset
          if startOffset <= index < endOffset
            tokenSelectionIndices.push(index - startOffset)
            selectionIndices.shift()
          else break

        if tokenSelectionIndices.length
          console.log(tokenSelectionIndices)

        chunk = chunk[matchedText.length..]
        startOffset = endOffset

        if tokenKind is 'WHITESPACE'
          continue

        tokens.push [tokenKind, matchedText, tokenSelectionIndices]
        break

    return tokens
