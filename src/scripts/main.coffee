window.F = {}

workspaceEl = document.getElementById 'workspace'
testEl = document.getElementById 'testarea'

testMatch = ->
  regexpStr = workspaceEl.innerText

  # Break apart the regexpStr into its components
  match = regexpStr.match(/^\/{3}([\s\S]+?)\/{3}([imgy]{0,4})$/)

  return unless match

  [regexpStr, body, flags] = match
  testMatch(body, flags)

  # Remove decorators from body
  strippedBody = body.replace(/[\ufeff\u200b]+/g, '')
    .replace(/\//g, '\\/')
    .replace(/([^\\])\s/g, ($0, $1) -> $1)

  try
    regexp = new RegExp(strippedBody, flags)

    # Display RegExp matches in the test area
    testEl.innerHTML = testEl.innerText.replace(regexp, '<span class="match">$&</span>')
  catch err
    console.error err.message

  return body

testEl.addEventListener 'keyup', (e) ->
  testMatch()

workspaceEl.addEventListener 'keyup', (e) ->
  # Clean any existing selection boundary placeholders
  # and add new selection boundary placeholders.
  F.Ranges.clearBoundaries(workspaceEl)
  F.Ranges.insertBoundaries()

  body = testMatch()

  tokens = F.Lexer.tokenize(body)
  formatter = new F.Formatter(tokens)

  [formattedEl, rangeData] = formatter.format()

  workspaceEl.innerHTML = ''
  workspaceEl.appendChild(formattedEl)

  # Reset the selection ranges
  F.Ranges.clearRanges()
  range = F.Ranges.createRange(rangeData.startNode, rangeData.startOffset, rangeData.endNode, rangeData.endOffset)
  F.Ranges.addRange(range)
