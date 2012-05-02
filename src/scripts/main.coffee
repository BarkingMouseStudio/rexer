# TODO: code-folding
# TODO: inline comments
# TODO: share w/ url shortener
# TODO: highlight editing block
# TODO: auto-format
# TODO: auto-correct/escape invalid regexp
# TODO: cannot enter invalid regexp
# TODO: auto-suggestions

window.F = {}

domready ->
  workspaceEl = document.getElementById 'workspace'

  workspaceEl.addEventListener 'keyup', (e) ->
    F.Ranges.clearBoundaries(workspaceEl)
    F.Ranges.insertBoundaries()

    tokens = F.Lexer.tokenize(regexpStr = workspaceEl.innerText)
    console.log tokens.map (token) ->
      [tag, value] = token
      return tag
    F.Ranges.clearBoundaries(workspaceEl)

    ###
    formatter = new F.Formatter(tokens)

    [formattedEl, ranges] = formatter.format()

    workspaceEl.innerHTML = ''
    workspaceEl.appendChild(formattedEl)

    F.Ranges.clearRanges()
    while rangeData = ranges.pop()
      range = F.Ranges.createRange(rangeData.startEl.childNodes[0], rangeData.startOffset, rangeData.endEl.childNodes[0], rangeData.endOffset)
      F.Ranges.addRange(range)
      ###
