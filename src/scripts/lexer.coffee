window.F or= {}

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
    LINEBOUNDARY: /^∆/
    WHITESPACE: /^\s+/

  # Controls the tokenization priority
  @tokenPriority: [
    'SPECIAL_CHAR'
    'WHITESPACE_CHAR'
    'ESCAPED_CHAR'
    'LINEBOUNDARY'
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
    'PROLOGUE'
    'EPILOGUE'
    'OTHER'
  ]

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
    startOffset = oldStartOffset = endOffset = 0
    tokens = []

    # Selection boundary indices
    selectionIndices = Lexer.getIndices(chunk, '√')
    accountedIndices = 0

    # Remove selection boundaries
    chunk = chunk.replace(/√+/g, '')
    length = chunk.length

    # Iterate of the remaining regexp string until its all gone
    `chunking://`
    while chunk

      for tokenKind in Lexer.tokenPriority
        unless match = Lexer.tokenRegex[tokenKind].exec chunk
          continue

        # Prologue only valid at 0
        if tokenKind is 'PROLOGUE' and startOffset isnt 0
          continue

        [matchedText] = match
        endOffset = startOffset + matchedText.length

        chunk = chunk[matchedText.length..]
        oldStartOffset = startOffset
        startOffset = endOffset

        if tokenKind is 'WHITESPACE'
          `continue chunking`

        if tokenKind is 'LINEBOUNDARY'
          `continue chunking`

        tokenSelectionIndices = []
        
        while selectionIndices.length
          index = selectionIndices[0] - accountedIndices
          if (oldStartOffset <= index <= endOffset) or (index is endOffset and index is length)
            tokenSelectionIndices.push(index - oldStartOffset)
            accountedIndices++
            selectionIndices.shift()
          else break

        matchedText = matchedText.replace(/∆/g, '')
        tokens.push [tokenKind, matchedText, tokenSelectionIndices]
        `continue chunking`

      console.log 'Fucked up character chausing an infinite loop...',
        'previous', tokens[tokens.length - 1],
        'last', chunk[0],
        'chunk', chunk
      chunk = chunk[1..]

    return tokens
