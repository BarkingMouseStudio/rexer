CodeMirror.modeExtensions or= {}

CodeMirror.modeExtensions['rexer'] =
  commentStart: "###",
  commentEnd: "###",

  getNonBreakableBlocks: (text) ->
    nonBreakableRegExps = [
      /(\[\^?)((?:(?:[^\\]\\\])|.)*?)\]/ # char group
      /[ ]#(.*)$/m # comment
      # escaped characters!!!
    ]

    nonBreakableBlocks = []

    for nonBreakableRegExp in nonBreakableRegExps
      offset = 0

      while offset < text.length
        match = text.substr(offset).match(nonBreakableRegExp)

        break unless match

        [matchedText] = match
        length = matchedText.length

        nonBreakableBlocks.push
          text: matchedText
          start: offset + match.index
          end: offset + match.index + length

        offset += match.index + Math.max(1, length)

    nonBreakableBlocks.sort (a, b) ->
      a.start - b.start

  autoFormatLineBreaks: (text) ->
    lineSplitter = ///
      (
        [^\\]
      )
      (
        (?:
          (?:\|)
          |
          (?:\((?:(?:\?\:)|(?:\?\=)|(?:\?\!)|(?:\?\<\=)|(?:\?\<\!))?)
          |
          (?:\)
            (?:
              (?:\?)
              |
              (?:[\+\*]\??)
            )?
          )
        )
        (?:\s+\#[ ].*$)?
      ) ///gm

    if nonBreakableBlocks = @getNonBreakableBlocks(text)
      result = ''
      offset = 0

      for nonBreakableBlock in nonBreakableBlocks
        if nonBreakableBlock.start > offset # break lines till the block
          result += text.substring(offset, nonBreakableBlock.start).replace(lineSplitter, '$1\n$2')
          offset = nonBreakableBlock.start

        if nonBreakableBlock.start <= offset <= nonBreakableBlock.end # skip non-breakable block
          result += text.substring(offset, nonBreakableBlock.end)
          offset = nonBreakableBlock.end

      if offset < text.length - 1
        result += text.substr(offset).replace(lineSplitter, '$1\n$2')

      return result

    return text.replace(lineSplitter, '$1\n$2')

CodeMirror.defineMode 'rexer', (config, mode) ->
  { indentUnit } = config

  tokenRegExps =
    prologue: /^\/{3}\s+/
    epilogue: /^\s*\/{3}([imgy]{0,4})$/
    special_char: /^\\[wWdDsSbB]/
    whitespace_char: /^\\[tnr]/
    escaped_char: /^\\./
    escaped_dollar: /^\${2}/
    input_start: /^\^/
    input_end: /^\$/
    quantifier: /^(?:(\?)|([\+\*]\??))/
    range: /^\{(?:(\d*,\d+)|(\d+,\d*))\}/
    group_start: /^\((?:(?:\?\:)|(?:\?\=)|(?:\?\!)|(?:\?\<\=)|(?:\?\<\!))?/
    group_end: /^\)/
    char_group: /// ^
      (\[\^?)
      (
        (
          ([^\\]\\\])|.
        )*
      )
      \]
      ///
    or: /^\|/
    other: /^[^\(\)\|\[\]\?\+\*\^\$\\\s]+/
    comment: /^[ ]#(.*)$/
    whitespace: /^\s+/

  tokenPriority = [
    'special_char'
    'whitespace_char'
    'escaped_char'
    'comment'
    'input_start'
    'escaped_dollar'
    'input_end'
    'quantifier'
    'group_start'
    'group_end'
    'or'
    'range'
    'char_group'
    'prologue'
    'epilogue'
    'whitespace'
    'other'
  ]

  tokenize = (stream, state) ->
    for tokenKind in tokenPriority
      unless match = stream.match(tokenRegExps[tokenKind])
        continue

      currentLength = stream.current().length

      if tokenKind is 'prologue' and state.offset isnt 0
        stream.backUp(currentLength)
        continue

      state.offset += currentLength

      if tokenKind is 'group_start'
        state.indented++

      if tokenKind is 'group_end'
        state.indented--

      return tokenKind.toLowerCase()

    console.warn('Character not matched by any token:', stream.next())
    return null

  return {
    startState: (base) ->
      indented: base or 0
      tokenize: tokenize
      offset: 0

    token: tokenize

    indent: (state, textAfter) ->
      if tokenRegExps.group_end.test(textAfter)
        state.indented--
      return state.indented * indentUnit

    electricChars: '\/()|'
  }
