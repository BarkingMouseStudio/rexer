# TODO: single-line regex
# TODO: fix DOM Error 1 (random)
# TODO: fix DOM Error 8 (entering whitespace via backspace)
# FEATURE: put quantifiers on group_end line
# FEATURE: line numbers
# FEATURE: inline comments (Danielle is writing copy)
# FEATURE: sharing
# FEATURE: highlighting current
# FEATURE: interactive tutorial

window.F or= {}

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
