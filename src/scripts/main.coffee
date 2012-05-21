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
    .replace(/[\ufeff∆]+/g, '') # Remove decorators from body
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

formatRegExp = (regExpStr) ->
  regExpStr = regExpStr
    .replace(/∆+/g, '') # Remove decorators from body
    .replace(/[ \t]+/g, '')
    .replace(/\ufeff[\r\n]/g, '\ufeff∆')
    .replace(/[\r\n]\ufeff/g, '∆\ufeff')
    .replace(/[\r\n]+/g, '')

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
  F.Ranges.insertBoundaries()

  testMatch(workspaceEl.innerText)
  formatRegExp(workspaceEl.innerText)
