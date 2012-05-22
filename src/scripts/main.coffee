window.F or= {}

F.Formatter = class Formatter
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

      for startOffset, i in indices
        endOffset = indices[++i]
        rangeData.startNode = contentEl.childNodes[0]
        rangeData.startOffset = startOffset
        rangeData.endNode = contentEl.childNodes[0]
        rangeData.endOffset = endOffset

    return [@formattedEl, rangeData]

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

F.Ranges = Ranges =
  hiddenCharacter: '√'
  boundaryClassName: 'selection_boundary'

  createRange: (startNode, startOffset, endNode, endOffset) ->
    try
      range = document.createRange()
      range.setStart(startNode, startOffset)
      range.setEnd(endNode, endOffset)
    catch err
      console.error err
    return range

  clearRanges: (selection = window.getSelection()) ->
    selection.removeAllRanges() if selection.rangeCount
    return selection

  addRange: (range, selection = window.getSelection()) ->
    selection.addRange(range)

  clearBoundaries: (el) ->
    for rangeEl in el.querySelectorAll(".#{Ranges.boundaryClassName}")
      rangeEl.parentNode.removeChild(rangeEl)

  insertStringAt: (str) ->
    selection = window.getSelection()
    unless selection.rangeCount
      return
    range = window.getSelection().getRangeAt(0).cloneRange()

    rangeStartText = document.createTextNode(str)
    rangeStartEl = document.createElement 'span'
    rangeStartEl.className = 'suggestion'
    rangeStartEl.appendChild(rangeStartText)
    range.insertNode(rangeStartEl)

  insertBoundaries: ->
    selection = window.getSelection()
    unless selection.rangeCount
      return
    range = window.getSelection().getRangeAt(0).cloneRange()

    rangeStartText = document.createTextNode(Ranges.hiddenCharacter)
    rangeStartEl = document.createElement 'span'
    rangeStartEl.className = Ranges.boundaryClassName
    rangeStartEl.appendChild(rangeStartText)
    range.insertNode(rangeStartEl)

    range.collapse(false) # collapse to end

    rangeEndText = document.createTextNode(Ranges.hiddenCharacter)
    rangeEndEl = document.createElement 'span'
    rangeEndEl.className = Ranges.boundaryClassName
    rangeEndEl.appendChild(rangeEndText)
    range.insertNode(rangeEndEl)

    range.detach()

workareaEl = document.getElementById 'workarea'
testEl = document.getElementById 'testarea'

testMatch = (regExpStr) ->
  # Break apart the regExpStr into its components
  regExpStr = regExpStr
    .replace(/[√∆]+/g, '') # Remove decorators from body
  match = regExpStr.match(/^\/{3}([\s\S]+?)\/{3}([imgy]{0,4})$/)
  unless match
    return

  [regExpStr, body, flags] = match

  body = body
    .replace(/[√∆]+/g, '') # Remove decorators from body
    .replace(/([^\\])\s/g, ($0, $1) -> $1) # removes unescapde whitespace

  try
    regExp = new RegExp(body, flags)

    # Display RegExp matches in the test area
    testEl.innerHTML = '<div>' + 
      testEl.innerText
        .replace(regExp, '<span class="match">$&</span>')
        .replace(/\n/g, '</div><div>') + '</div>'
  catch err
    console.error err.message

testEl.addEventListener 'keyup', (e) ->
  testMatch(workareaEl.innerText)

formatRegExp = (regExpStr) ->
  regExpStr = regExpStr
    .replace(/∆+/g, '') # Remove decorators from body
    .replace(/√[\r\n]/g, '√∆')
    .replace(/[\r\n]√/g, '∆√')
    .replace(/[ \t\r\n]+/g, '')

  tokens = F.Lexer.tokenize(regExpStr)
  formatter = new F.Formatter(tokens)

  [formattedEl, rangeData] = formatter.format()

  workareaEl.innerHTML = ''
  workareaEl.appendChild(formattedEl)

  # Reset the selection ranges
  F.Ranges.clearRanges()
  range = F.Ranges.createRange(rangeData.startNode, rangeData.startOffset, rangeData.endNode, rangeData.endOffset)
  F.Ranges.addRange(range)

testMatch(workareaEl.innerText)
formatRegExp(workareaEl.innerText)

workareaEl.addEventListener 'keyup', (e) ->
  if e.keyCode in [
    91 # ⌘
  ]
    return

  F.Ranges.clearBoundaries(workareaEl)
  F.Ranges.insertBoundaries()

  testMatch(workareaEl.innerText)
  formatRegExp(workareaEl.innerText)
