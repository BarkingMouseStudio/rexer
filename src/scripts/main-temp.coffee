# Token-matching RegExps.
# Each matches from the beginning of the string and
# some characters that represent a `RegExp` token.
tokenRegex =
  PROLOGUE: /^\/{3}/
  EPILOGUE: /^\/{3}([imgy]{0,4})∆*$/
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
  CHAR_GROUP: /^(\[\^?)((?:(?:[^\\]\\\])|.)*?)\]/
  OTHER: /^[^\(\)\|\[\]\?\+\*\^\$\\\s*]+/
  WHITESPACE: /^\s+/
  COMMENT: /^[ ]#(.*)$/

# Controls the tokenization priority.
# There's some overlap in the tokens and a prioritization
# order is needed to disambiguate.
tokenPriority = [
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


# Tokenize a RegExp string and return an `Array` of tokens.
tokenize = (chunk) ->
  startOffset = 0
  tokens = []

  # Iterate the remaining RegExp string until its all gone
  `chunking://`
  while chunk #`

    for tokenKind in tokenPriority
      unless match = tokenRegex[tokenKind].exec chunk
        continue

      # Prologue only valid at 0
      if tokenKind is 'PROLOGUE' and startOffset isnt 0
        continue

      [matchedText] = match

      startOffset += matchedText.length

      chunk = chunk[matchedText.length..]
      tokens.push [tokenKind, matchedText, tokenSelectionIndices]
      `continue chunking`

    # Sometimes we get a character we didn't account for.
    console.warn 'Characters not matched by any token:', chunk

    # Eat the next character to prevent an infinite loop.
    chunk = chunk[1..]

  return tokens

# Takes a RegExp string and attempts to match the test area.
testRegExpMatch = (regExpStr) ->
  # Remove decorators from body.
  regExpStr = regExpStr.replace(/[√∆]+/g, '') 

  # Break apart the regExpStr into its components.
  match = regExpStr.match(/^\/{3}([\s\S]+?)\/{3}([imgy]{0,4})$/m)

  unless match
    return false

  [regExpStr, body, flags] = match

  # Remove comments
  body = body.replace(/[ ]#(.*)$/, '')

  # Removes unescaped whitespace
  body = body.replace(/([^\\])\s/g, ($0, $1) -> $1)

  try
    regExp = new RegExp(body, flags)

    # Display RegExp matches in the test area
    testareaEl.innerHTML = '<div>' + 
      testareaEl.innerText
        .replace(regExp, '<span class="match">$&</span>')
        .replace(/\n/g, '</div><div>') + '</div>'
    return true
  catch err
    console.error err.message
    return false

testareaEl.addEventListener 'keyup', (e) ->
  testRegExpMatch(workareaEl.innerText)

workareaEl.addEventListener 'keyup', (e) ->
  return if e.keyCode in [
    16 # ⇧
    17 # ⌃
    18 # ⌥
    91 # L⌘
    93 # R⌘
  ]

  for rangeEl in workareaEl.querySelectorAll(".#{selectionBoundaryClass}")
    rangeEl.parentNode.removeChild(rangeEl)

  testRegExpMatch(workareaEl.innerText)

  insertSelectionBoundaries()

  # Cleanup the string and do some tricky handling
  # of line-boundaries so that the cursor ends up in
  # the right place.
  regExpStr = workareaEl.innerText

  # Remove decorators from body
  regExpStr = regExpStr.replace(/∆+/g, '')

  regExpStr = regExpStr
    .replace(/[\r\n](√+)/g, '∆$1') # Selection at beginning of line
    .replace(/(√+)[\r\n]/g, '$1∆') # Selection at end of line

  # Selection inside spacing at beginning of line
  if e.keyCode is 40 # ↓
    regExpStr = regExpStr.replace(/[\r\n][ ]+(√+)[ ]+/g, '∆$1')
  else
    regExpStr = regExpStr.replace(/[\r\n][ ]+(√+)[ ]+/g, '$1∆')

  regExpStr = regExpStr
    .replace(/[\r\n][ ]+(√+)/g, '∆$1') # Selection at beginning of characters on line
    .replace(/[\t\r\n]+/g, '') # Remove most whitespace

  console.log regExpStr

  regExpStr = regExpStr
    .replace /(?:([ ]\[))|(?:([^\\])[ ]+)/g, ($0, $1, $2) ->
      console.log $1
      $1 or $2 # Remove any unescaped spaces
  console.log regExpStr

  regExpStr = regExpStr
    .replace(/∆(√+)∆/g, '$1∆') # Selection within line breaks (backspacing a now empty line)

  tokens = tokenize(regExpStr)

  [formattedEl, rangeData] = format(tokens)

  workareaEl.innerHTML = ''
  workareaEl.appendChild(formattedEl)

  selection = window.getSelection()

  # Reset existing selection ranges
  if selection.rangeCount
    selection.removeAllRanges()

  # Add new selection ranges
  try
    range = document.createRange()
    range.setStart(rangeData.startNode, rangeData.startOffset)
    range.setEnd(rangeData.endNode, rangeData.endOffset)
    selection.addRange(range)
  catch err
    console.error 'Failed to add range:', err
