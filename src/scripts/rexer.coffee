CodeMirror.modeExtensions['css'] =
  autoFormatLineBreaks: (text) ->
    return text.replace(/(;|\{|\})([^\r\n])/g, '$1\n$2')

CodeMirror.defineMode 'rexer', (config, mode) ->
  indentUnit = config.indentUnit

  tokenRegExps =
    prologue: /^\/{3}/
    epilogue: /^\/{3}([imgy]{0,4})∆*$/
    special_char: /^\\[wWdDsSbB]/
    whitespace_char: /^\\[tnr]/
    escaped_char: /^\\./
    input_start: /^\^/
    input_end: /^\$/
    escaped_dollar: /^\${2}/
    quantifier: /^(?:(\?)|([\+\*]\??))/
    group_start: /^\((\?(?:(?:\:)|(?:\=)|(?:\!)|(?:\<\=)|(?:\<\!))?)?/
    group_end: /^\)/
    or: /^\|/
    range: /^\{(?:(\d*,\d+)|(\d+,\d*))\}/
    char_group: /^(\[\^?)((?:(?:[^\\]\\\])|.)*?)\]/
    other: /^[^\(\)\|\[\]\?\+\*\^\$\\\s*]+/
    whitespace: /^\s+/
    comment: /^[ ]#(.*)$/

  tokenPriority = [
    'special_char'
    'whitespace_char'
    'escaped_char'
    'comment'
    'whitespace'
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

      if tokenKind is 'group_start'
        state.stack.push('(')

      if tokenKind is 'group_end'
        state.stack.pop(')')

      return tokenKind.toLowerCase()

    console.warn('Character not matched by any token:', stream.next())
    return null

  return {
    startState: (base) ->
      indented: base
      tokenize: tokenize
      stack: []

    token: tokenize

    indent: (state, textAfter) ->
      return state.indented * indentUnit

      ###
      if state.tokenize isnt tokenize and state.tokenize isnt null
        return 0

      ctx = state.context
      firstChar = textAfter and textAfter.charAt(0)
      if ctx.type is "statement" and firstChar is "}"
        ctx = ctx.prev

      closing = firstChar is ctx.type
      if ctx.type is "statement"
        return ctx.indented + (if firstChar is "{" then 0 else indentUnit)
      else if ctx.align
        return ctx.column + (if closing then 0 else 1)
      else
        return ctx.indented + (if closing then 0 else indentUnit)
      ###

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
