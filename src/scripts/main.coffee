# Formats a token array into a DOM element.
class Formatter
  constructor: (tokens) ->
    @tokens = tokens.slice 0
    @currentParentEl = @formattedEl = document.createElement 'div'
    @previousParentEls = []
    @indent = 0

  indentText: ->
    i = @indent
    @appendText '  ', 'INDENT' while i-- > 0

  appendText: (value, tag = '') ->
    textNode = document.createTextNode(value)
    textEl = document.createElement 'span'
    textEl.className = "token #{tag?.toLowerCase()}"
    textEl.appendChild(textNode)
    @currentParentEl.appendChild(textEl)
    return textEl

  format: ->
    rangeData = {}

    while token = @tokens.shift()
      [tag, value, indices] = token 
      switch tag
        when 'GROUP_START'
          newParentEl = document.createElement 'div'
          newParentEl.className = 'group_wrapper'
          @currentParentEl.appendChild(newParentEl)
          @previousParentEls.push(@currentParentEl)
          @currentParentEl = newParentEl

          @indentText()
          contentEl = @appendText(value, tag) # append `(`

          newParentEl = document.createElement 'div'
          newParentEl.className = 'group_content'
          @currentParentEl.appendChild(newParentEl)
          @previousParentEls.push(@currentParentEl)
          @currentParentEl = newParentEl

          @indent++
          if @tokens[0]?[0] not in ['GROUP_START', 'OR']
            @indentText()
        when 'GROUP_END'
          @currentParentEl = @previousParentEls.pop()

          @indent--
          @indentText()
          contentEl = @appendText(value, tag) # append `)`

          @currentParentEl = @previousParentEls.pop()
          if @tokens[0]?[0] not in ['GROUP_START', 'GROUP_END', 'OR']
            @indentText()
        when 'OR'
          newParentEl = document.createElement 'div'
          newParentEl.className = 'or'
          @currentParentEl.appendChild(newParentEl)
          @previousParentEls.push(@currentParentEl)
          @currentParentEl = newParentEl
          @indentText()
          contentEl = @appendText(value, tag) # append `|`
          @currentParentEl = @previousParentEls.pop()
          if @tokens[0]?[0] not in ['GROUP_START', 'OR']
            @indentText()
        else contentEl = @appendText(value, tag)

      if indices.length
        [startOffset, endOffset] = indices
        rangeData.startNode = contentEl.childNodes[0]
        rangeData.startOffset = startOffset
        rangeData.endNode = contentEl.childNodes[0]
        rangeData.endOffset = endOffset

    return [@formattedEl, rangeData]


workareaEl = document.getElementById 'workarea'
testareaEl = document.getElementById 'testarea'

selectionBoundaryChar = '√'
selectionBoundaryClass = 'selection_boundary'

lineBoundaryChar = '∆'

# Token-matching RegExps.
# Each matches from the beginning of the string and
# some characters that represent a `RegExp` token.
tokenRegex =
  PROLOGUE: /^\/{3}/
  EPILOGUE: /^\/{3}([imgy]{0,4})∆*$/
  SINGLELINE_PROLOGUE: /^\//
  SINGLELINE_EPILOGUE: /^\/([imgy]{0,4})∆*$/
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
  OTHER: /^[^\#\(\)\|\[\]\?\+\*\^\$\\\s*]+/
  LINEBOUNDARY: /^∆/
  WHITESPACE: /^\s+/

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
  'SINGLELINE_PROLOGUE'
  'SINGLELINE_EPILOGUE'
  'OTHER'
]


# Gets an array of indices for the `needle` in the `haystack`.
# This is used to find selection boundaries in a
# RegExp string before tokenization.
getIndices = (haystack, needle) ->
  indices = []
  index = -1
  while true
    index = haystack.indexOf(needle, index)
    break if index is -1
    indices.push(index)
    index += needle.length
  return indices


# Insert characters to represent the beginning and end of a selection range.
insertSelectionBoundaries = ->
  selection = window.getSelection()

  unless selection.rangeCount
    return

  range = selection.getRangeAt(0).cloneRange()

  # Create a selection boundary at the beginning of the range.
  rangeStartText = document.createTextNode(selectionBoundaryChar)
  rangeStartEl = document.createElement 'span'
  rangeStartEl.className = selectionBoundaryClass
  rangeStartEl.appendChild(rangeStartText)
  range.insertNode(rangeStartEl)

  # Collapse to end and create a selection boundary at the end of the range.
  range.collapse(false)

  rangeEndText = document.createTextNode(selectionBoundaryChar)
  rangeEndEl = document.createElement 'span'
  rangeEndEl.className = selectionBoundaryClass
  rangeEndEl.appendChild(rangeEndText)
  range.insertNode(rangeEndEl)

  # Cleanup the range from memory
  range.detach()


# Tokenize a RegExp string and return an `Array` of tokens.
tokenize = (chunk) ->
  startOffset = oldStartOffset = endOffset = 0
  tokens = []

  # Selection boundary indices
  selectionIndices = getIndices(chunk, selectionBoundaryChar)
  accountedIndices = 0

  # Remove selection boundaries
  chunk = chunk.replace(/√+/g, '')
  length = chunk.length

  # Iterate the remaining RegExp string until its all gone
  `chunking://`
  while chunk
    #`

    for tokenKind in tokenPriority
      unless match = tokenRegex[tokenKind].exec chunk
        continue

      # Prologue only valid at 0
      if tokenKind in ['PROLOGUE', 'SINGLELINE_PROLOGUE'] and startOffset isnt 0
        continue

      [matchedText] = match

      if tokenKind in ['SINGLELINE_PROLOGUE', 'SINGLELINE_EPILOGUE']
        matchedText = matchedText.replace(/\//, '///')

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

    # Sometimes we get a character we didn't account for.
    # Eat the next character to prevent an infinite loop.
    console.warn 'Fucked up character that did not match a token...',
      'previous', tokens[tokens.length - 1],
      'last', chunk[0],
      'chunk', chunk
    chunk = chunk[1..]

  return tokens

# Takes a RegExp string and attempts to match the test area.
testRegExpMatch = (regExpStr) ->
  # Remove decorators from body.
  regExpStr = regExpStr.replace(/[√∆]+/g, '') 

  # Break apart the regExpStr into its components.
  match = regExpStr.match(/^\/{3}([\s\S]+)\/{3}([imgy]{0,4})$/)

  unless match
    return

  [regExpStr, body, flags] = match

  # Removes unescapde whitespace.
  body = body.replace(/([^\\])\s/g, ($0, $1) -> $1)

  try
    regExp = new RegExp(body, flags)

    # Display RegExp matches in the test area
    testareaEl.innerHTML = '<div>' + 
      testareaEl.innerText
        .replace(regExp, '<span class="match">$&</span>')
        .replace(/\n/g, '</div><div>') + '</div>'
  catch err
    console.error err.message

formatRegExp = (regExpStr) ->
  regExpStr = regExpStr
    .replace(/∆+/g, '') # Remove decorators from body
    .replace(/√[\r\n]/g, '√∆')
    .replace(/[\r\n]√/g, '∆√')
    .replace(/[\t\r\n]+/g, '')
    .replace(/([^\\])[ ]+/g, ($0, $1) -> $1)

  tokens = tokenize(regExpStr)
  formatter = new Formatter(tokens)

  [formattedEl, rangeData] = formatter.format()

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
    console.error err


testareaEl.addEventListener 'keyup', (e) ->
  testRegExpMatch(workareaEl.innerText)

workareaEl.addEventListener 'keyup', (e) ->
  # Ignoring some characters.
  return if e.keyCode in [
    16 # ⇧
    17 # ⌃
    18 # ⌥
    91 # ⌘
  ]

  for rangeEl in workareaEl.querySelectorAll(".#{selectionBoundaryClass}")
    rangeEl.parentNode.removeChild(rangeEl)

  insertSelectionBoundaries()

  regExpStr = workareaEl.innerText
    .replace(/∆+/g, '') # Remove existing decorators from body
    .replace(/√[\r\n]/g, '√∆')
    .replace(/[\r\n]√/g, '∆√')
    .replace(/[\t\r\n]+/g, '')
    .replace(/([^\\])[ ]+/g, ($0, $1) -> $1)

  formatRegExp(regExpStr)
  testRegExpMatch(regExpStr)
