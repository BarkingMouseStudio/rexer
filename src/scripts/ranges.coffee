F.Ranges = Ranges =
  hiddenCharacter: '\ufeff'
  boundaryClassName: 'selection_boundary'

  createRange: (startNode, startOffset, endNode, endOffset) ->
    range = document.createRange()
    range.setStart(startNode, startOffset)
    range.setEnd(endNode, endOffset)
    return range

  clearRanges: (selection = window.getSelection()) ->
    selection.removeAllRanges() if selection.rangeCount
    return selection

  addRange: (range, selection = window.getSelection()) ->
    selection.addRange(range)

  clearBoundaries: (el) ->
    for rangeEl in el.querySelectorAll(".#{Ranges.boundaryClassName}")
      rangeEl.parentNode.removeChild(rangeEl)

  insertBoundaries: ->
    selection = window.getSelection()
    return unless selection.rangeCount
    range = window.getSelection().getRangeAt(0).cloneRange()

    rangeStartText = document.createTextNode(Ranges.hiddenCharacter)
    rangeStartEl = document.createElement 'span'
    rangeStartEl.className = Ranges.boundaryClassName
    rangeStartEl.appendChild(rangeStartText)
    range.insertNode(rangeStartEl)

    range.collapse(false) # collapse to end

    rangeEndText = document.createTextNode(Ranges.hiddenCharacter)
    rangeEndEl = document.createElement 'span'
    rangeEndEl.className = Ranges.boundaryClassName
    rangeEndEl.appendChild(rangeEndText)
    range.insertNode(rangeEndEl)

    range.detach()
