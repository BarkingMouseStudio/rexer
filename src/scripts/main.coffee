window.F = {}

# DEFAULTS
workspaceEl = document.getElementById 'workspace'
testEl = document.getElementById 'testarea'

# HELPER FUNCTIONS
# checks to see if it's a valid regex
# returns if not
# breaks apart 
testMatch = (regExpStr) ->
  # Break apart the regExpStr into its components
  unless match = regExpStr.match(/^\/{3}([\s\S]+?)\/{3}([imgy]{0,4})$/)
    return

  [regExpStr, body, flags] = match

  body = body
    .replace(/[√∆]+/g, '') # Remove decorators from body
    .replace(/\//g, '\\/') #'# excape forward slashes
    .replace(/([^\\])\s/g, ($0, $1) -> $1) # removes unescapde whitespace

  try
    regExp = new RegExp(body, flags)

    # Display RegExp matches in the test area
    testEl.innerHTML = testEl.innerText.replace(regExp, '<span class="match">$&</span>')
  catch err
    console.error err.message

testEl.addEventListener 'keyup', (e) ->
  testMatch(workspaceEl.innerText)

# TODO: single-line regex
# TODO: interactive tutorial
formatRegExp = (regExpStr) ->
  regExpStr = regExpStr
    .replace(/∆+/g, '') # Remove decorators from body
    .replace(/√[\r\n]/g, '√∆')
    .replace(/[\r\n]√/g, '∆√')
    .replace(/[ \t\r\n]+/g, '')

  tokens = F.Lexer.tokenize(regExpStr)
  formatter = new F.Formatter(tokens)

  [formattedEl, rangeData] = formatter.format()

  workspaceEl.innerHTML = ''
  workspaceEl.appendChild(formattedEl)

  # Reset the selection ranges
  F.Ranges.clearRanges()
  range = F.Ranges.createRange(rangeData.startNode, rangeData.startOffset, rangeData.endNode, rangeData.endOffset)
  F.Ranges.addRange(range)

workspaceEl.addEventListener 'keyup', (e) ->
  if e.keyCode in [
    91 # ⌘
  ]
    return

  F.Ranges.insertBoundaries()

  testMatch(workspaceEl.innerText)
  formatRegExp(workspaceEl.innerText)
