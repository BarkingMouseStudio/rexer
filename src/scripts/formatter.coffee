F.Formatter = class Formatter
  constructor: (tokens) ->
    @tokens = tokens.slice 0
    @currentParentEl = @formattedEl = document.createElement 'ol'
    @previousParentEls = []
    @indent = 0

  indentText: ->
    i = @indent
    @appendText '  ', 'INDENT' while i-- > 0

  appendText: (value, tag = '') ->
    textNode = document.createTextNode(value)
    textEl = document.createElement 'span'
    textEl.className = "token #{tag?.toLowerCase()}"
    textEl.appendChild(textNode)
    @currentParentEl.appendChild(textEl)
    return textEl

  format: ->
    rangeData = {}

    while token = @tokens.shift()
      [tag, value, indices] = token 
      switch tag
        when 'GROUP_START'
          newParentEl = document.createElement 'div'
          newParentEl.className = 'group_wrapper'
          @currentParentEl.appendChild(newParentEl)
          @previousParentEls.push(@currentParentEl)
          @currentParentEl = newParentEl

          @indentText()
          contentEl = @appendText(value, tag) # append `(`

          newParentEl = document.createElement 'div'
          newParentEl.className = 'group_content'
          @currentParentEl.appendChild(newParentEl)
          @previousParentEls.push(@currentParentEl)
          @currentParentEl = newParentEl

          @indent++
          if @tokens[0]?[0] not in ['GROUP_START', 'OR']
            @indentText()
        when 'GROUP_END'
          @currentParentEl = @previousParentEls.pop()

          @indent--
          @indentText()
          contentEl = @appendText(value, tag) # append `)`

          @currentParentEl = @previousParentEls.pop()
          if @tokens[0]?[0] not in ['GROUP_START', 'GROUP_END', 'OR']
            @indentText()
        when 'OR'
          newParentEl = document.createElement 'div'
          newParentEl.className = 'or'
          @currentParentEl.appendChild(newParentEl)
          @previousParentEls.push(@currentParentEl)
          @currentParentEl = newParentEl
          @indentText()
          contentEl = @appendText(value, tag) # append `|`
          @currentParentEl = @previousParentEls.pop()
          if @tokens[0]?[0] not in ['GROUP_START', 'OR']
            @indentText()
        else contentEl = @appendText(value, tag)

      for startOffset, i in indices
        endOffset = indices[++i]
        rangeData.startNode = contentEl.childNodes[0]
        rangeData.startOffset = startOffset
        rangeData.endNode = contentEl.childNodes[0]
        rangeData.endOffset = endOffset

    return [@formattedEl, rangeData]
