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

    try
      tokens = F.Lexer.tokenize regexpStr = workspaceEl.innerText
      console.log new RegExp regexpStr

      formatter = new F.Formatter(tokens)
      formattedHTML = formatter.format()

      workspaceEl.innerHTML = ''
      workspaceEl.appendChild(formattedHTML)

      formatter.createRanges()
    catch err
      F.Ranges.clearBoundaries(workspaceEl)
