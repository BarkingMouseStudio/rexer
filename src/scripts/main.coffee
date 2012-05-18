window.F = {}

workspaceEl = document.getElementById 'workspace'
testEl = document.getElementById 'testarea'

apply = (fn, ctx, args) -> fn.apply(ctx, args)
log = -> apply(console.log, console, arguments)

concat = Array::concat
unit = (a) -> [a]
push = (arr, a) -> (concat arr, (unit item))
map = (arr, fn) -> (fn a) for a in arr
at = (i) ->
  (arr) ->
    arr[i]
pluck = (arr, i) -> (map arr, at(i))

# strip = (str) -> str.replace(/\s+(?:#.*)?/g, '')
# clean = (str) -> str.replace(/[\ufeff]+/g, '')
# /\//g => '\\/'

testMatch = (body, flags='g') ->
  try
    # Replace non-escaped whitespace
    body = body.replace /([^\\])\s/g, ($0, $1) -> $1

    # Try to parse the RegExp (replacing selection boundaries)
    regexp = new RegExp(body, flags)

    # Display RegExp matches in the test area
    testEl.innerHTML = testEl.innerText.replace(regexp, '<span class="match">$&</span>')
  catch err
    console.error err.message

# Re-lex the RegExp on keyup events
workspaceEl.addEventListener 'keyup', (e) ->
  # Clean any existing selection boundary placeholders
  F.Ranges.clearBoundaries(workspaceEl)

  # Add new selection boundary placeholders
  F.Ranges.insertBoundaries()

  # Grab the innerText of the el and replace unwanted whitespace characters
  regexpStr = workspaceEl.innerText

  # Break apart the regexpStr into its components
  match = regexpStr.match(/^\/{3}([\s\S]+?)\/{3}([imgy]{0,4})$/)

  # An apparently invalid regex
  return unless match

  # Get each of the regexpStr components
  [regexpStr, body, flags] = match

  # Test for matches in the test area
  testMatch(body, flags)

  # Tokenize the string
  tokens = F.Lexer.tokenize(body)

  # Format the tokens
  formatter = new F.Formatter(tokens)

  # Get the formatter results
  [formattedEl, rangeData] = formatter.format()

  # Update the DOM
  workspaceEl.innerHTML = ''
  workspaceEl.appendChild(formattedEl)

  # Reset the selection ranges
  F.Ranges.clearRanges()
  range = F.Ranges.createRange(rangeData.startNode, rangeData.startOffset, rangeData.endNode, rangeData.endOffset)
  F.Ranges.addRange(range)
