F.Formatter = class Formatter
  constructor: (tokens) ->
    @tokens = tokens.slice 0
    @currentParentEl = @formattedEl = document.createElement 'div'
    @previousParentEls = []
    @indent = 0
    @rangeData = []

  indentText: ->
    i = @indent
    @appendText '  ', 'INDENT' while i-- > 0

  appendText: (value, tag = '') ->
    textNode = document.createTextNode(value)
    @lastEl = textEl = document.createElement 'span'
    textEl.className = "token #{tag?.toLowerCase()}"
    textEl.appendChild(textNode)
    @currentParentEl.appendChild(textEl)

  format: ->
    rangeData = {}

    while token = @tokens.shift()
      [tag, value, selection] = token 

      if contains_selection
        if rangeData.startOffset?
          rangeData.endEl = @lastEl
          rangeData.endOffset = @lastEl.innerText.length
          @rangeData.push(rangeData)
          rangeData = {}
        else
          rangeData.startEl = @lastEl
          rangeData.startOffset = @lastEl.innerText.length

      switch tag
        when 'GROUP_START'
          newParentEl = document.createElement 'div'
          newParentEl.className = 'group_wrapper'
          @currentParentEl.appendChild(newParentEl)
          @previousParentEls.push(@currentParentEl)
          @currentParentEl = newParentEl

          @indentText()
          @appendText(value, tag) # append `(`

          newParentEl = document.createElement 'div'
          newParentEl.className = 'group_content'
          @currentParentEl.appendChild(newParentEl)
          @previousParentEls.push(@currentParentEl)
          @currentParentEl = newParentEl

          @indent++
          @indentText()
        when 'GROUP_END'
          @currentParentEl = @previousParentEls.pop()

          @indent--
          @indentText()
          @appendText(value, tag) # append `)`

          @currentParentEl = @previousParentEls.pop()
        when 'OR'
          newParentEl = document.createElement 'div'
          newParentEl.className = 'or'
          @currentParentEl.appendChild(newParentEl)
          @previousParentEls.push(@currentParentEl)
          @currentParentEl = newParentEl
          @indentText()
          @appendText(value, tag) # append `|`
          @currentParentEl = @previousParentEls.pop()
          @indentText()
        else @appendText(value, tag)

    return [@formattedEl, @rangeData]
