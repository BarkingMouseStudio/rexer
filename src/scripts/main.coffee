window.F = {}

workspaceEl = document.getElementById 'workspace'
testEl = document.getElementById 'testarea'

testMatch = (regExpStr) ->
  # Break apart the regExpStr into its components
  unless match = regExpStr.match(/^\/{3}([\s\S]+?)\/{3}([imgy]{0,4})$/)
    return

  [regExpStr, body, flags] = match

  body = body
    .replace(/[\ufeff\u200b]+/g, '') # Remove decorators from body
    .replace(/\//g, '\\/')
    .replace(/([^\\])\s/g, ($0, $1) -> $1)

  try
    regExp = new RegExp(body, flags)

    # Display RegExp matches in the test area
    testEl.innerHTML = testEl.innerText.replace(regExp, '<span class="match">$&</span>')
  catch err
    console.error err.message

formatRegExp = (regExpStr) ->
  tokens = F.Lexer.tokenize(regExpStr)
  formatter = new F.Formatter(tokens)

  [formattedEl, rangeData] = formatter.format()

  workspaceEl.innerHTML = ''
  workspaceEl.appendChild(formattedEl)

  # Reset the selection ranges
  F.Ranges.clearRanges()
  range = F.Ranges.createRange(rangeData.startNode, rangeData.startOffset, rangeData.endNode, rangeData.endOffset)
  F.Ranges.addRange(range)

testEl.addEventListener 'keyup', (e) ->
  testMatch(workspaceEl.innerText)

workspaceEl.addEventListener 'keyup', (e) ->
  ###
  switch e.keyCode
    when 219 # [
      F.Ranges.insertStringAt(']')
    when 57
      F.Ranges.insertStringAt(')') if e.shiftKey
    else
      console.info e.keyCode
      ###

  F.Ranges.insertBoundaries()

  testMatch(workspaceEl.innerText)
  formatRegExp(workspaceEl.innerText)
