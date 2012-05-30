CodeMirror.modeExtensions or= {}

CodeMirror.modeExtensions['rexer'] =
  autoFormatLineBreaks: (text) ->
    return text
      .replace(/^\/{3}\s+/, '///\n')
      .replace(/\s+\/{3}([imgy]{0,4})$/, '\n///$1')
      .replace(/\((.*)\)/g, '\n(\n$1\n)\n')

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
    char_group: /^(\[\^?)((?:(?:[^\\]\\\])|.)*?)\]/
    or: /^\|/
    other: /^[^\(\)\|\[\]\?\+\*\^\$\\\s]+/
    comment: /^[ ]#(.*)$/

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

###
///
(
  (?:
    https?://
    |
    wwwd{0,3}[.]
    |
    [a-z0-9.-]+[.][a-z]{2,4}/
  )
  (?:
    [^s()&lt;&gt;]+
    |
    (
      (
        [^s()&lt;&gt;]+
        |
        (
          (
            [^s()&lt;&gt;]+
          )
        )
      )*
    )
  )+
  (?:
    (
      (
        [^s()&lt;&gt;]+
        |
        (
          (
            [^s()&lt;&gt;]+
          )
        )
      )*
    )
    |
    [^s`!()[]{};:'".,&lt;&gt;?«»“”‘’]
  )
)
///gi
###
