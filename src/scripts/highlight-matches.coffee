HighlightMatchesState = ->
  @marked = []
  return this

getHighlightMatchesState = (cm) ->
  return cm._highlightMatchesState or (cm._highlightMatchesState = new HighlightMatchesState())

clearMarks = (cm) ->
  state = getHighlightMatchesState(cm)
  for mark in state.marked
    mark.clear()
  state.marked = []

CodeMirror.defineExtension 'highlightMatches', (matchOn) ->
  clearMarks(this)
  state = getHighlightMatchesState(this)

  matchOnParts = matchOn.match(/^\/{3}([\S\s]+?)\/{3}([imgy]{0,4})$/m)

  unless matchOnParts
    return

  [matchOn, matchOnBody, matchOnFlags] = matchOnParts

  matchOnRegExp = new RegExp(matchOnBody.replace(/\//g, '\\/'), matchOnFlags)

  @operation =>
    unless @lineCount() < 2000 # expensive on big documents
      return

    cursor = @getSearchCursor(matchOnRegExp)

    while cursor.findNext()
      state.marked.push(@markText(cursor.from(), cursor.to(), 'CodeMirror-matchhighlight'))
