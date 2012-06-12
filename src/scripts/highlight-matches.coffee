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

  matchOnParts = matchOn.match(/^\/{3}\s+([\S\s]+?)\s+\/{3}([imgy]{0,4})$/m)

  unless matchOnParts
    return

  [matchOn, matchOnBody, matchOnFlags] = matchOnParts

  matchOnBody = matchOnBody
    .replace(/[ ]#(.*)$/m, '')
    .replace(/([^\\])\s+/g, '$1')
    .replace(/\//g, '\\/')

  matchOnRegExp = new RegExp(matchOnBody, matchOnFlags)

  @operation =>
    unless @lineCount() < 2000 # expensive on big documents
      return

    cursor = @getSearchCursor(matchOnRegExp)

    while cursor.findNext()
      state.marked.push(@markText(cursor.from(), cursor.to(), 'CodeMirror-matchhighlight'))
