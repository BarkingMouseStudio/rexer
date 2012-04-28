F.Formatter = class Formatter
  @comments:
    SPECIAL: 'Special character'
    WHITESPACE: 'Whitespace character'
    ESCAPED: 'Escaped character'
    INPUT_START: 'Match the beginning of the string'
    INPUT_END: 'Match the end of the string'
    ESCAPED_DOLLAR: 'Escaped dollar character'
    QUANTIFIER: 'Match the previous token by a particular quantity'
    GROUP_START: 'Opening group'
    GROUP_END: 'Closing group'
    OR: 'Match either the previous token _or_ the next'
    RANGE: 'Match the previous token by a particular range'
    CHAR_GROUP: 'Match characters in this group'

  constructor: (tokens) ->
    @tokens = tokens.slice 0
    @currentParentEl = @formattedEl = document.createElement 'div'
    @previousParentEls = []
    @rangeData = []
    @level = 0
    @comment = ''

  indentText: ->
    i = @level
    return indent = ('  ' while i-- > 0).join ''

  appendText: (value, tag = '') ->
    textNode = document.createTextNode(value)
    @lastEl = textEl = document.createElement 'span'
    textEl.className = "token #{tag?.toLowerCase()}"
    textEl.appendChild(textNode)
    @currentParentEl.appendChild(textEl)

  appendComment: ->
    return unless @comment
    @appendText(" # #{@comment}", 'COMMENT')
    @comment = ''

  createRanges: ->
    F.Ranges.clearRanges()
    while r = @rangeData.pop()
      range = F.Ranges.createRange(r.startNode.childNodes[0], r.startOffset, r.endNode.childNodes[0], r.endOffset)
      F.Ranges.addRange(range)

  format: ->
    rangeData = {}

    while token = @tokens.shift()
      [tag, value] = token 

      if tag is 'INPUT_START'
        @appendText(value, tag)
        @comment += Formatter.comments[tag]
      else if tag is 'INPUT_END'
        @appendText(value, tag)
        @comment += Formatter.comments[tag]
      else if tag is 'SELECTION_BOUNDARY'
        if typeof rangeData.startOffset is 'undefined'
          rangeData.startNode = @lastEl
          rangeData.startOffset = @lastEl.innerText.length
        else
          rangeData.endNode = @lastEl
          rangeData.endOffset = @lastEl.innerText.length
          @rangeData.push rangeData
          rangeData = {}
      else if tag is 'GROUP_START'
        @appendComment()
        newParentEl = document.createElement 'div'
        newParentEl.className = 'group_wrapper'
        @currentParentEl.appendChild(newParentEl)
        @previousParentEls.push(@currentParentEl)
        @currentParentEl = newParentEl

        @appendText(@indentText(), 'whitespace')
        @appendText(value, tag) # append `(`
        @comment += Formatter.comments[tag]
        @appendComment()

        newParentEl = document.createElement 'div'
        newParentEl.className = 'group_content'
        @currentParentEl.appendChild(newParentEl)
        @previousParentEls.push(@currentParentEl)
        @currentParentEl = newParentEl

        @level++
        @appendText(@indentText(), 'whitespace')
      else if tag is 'GROUP_END'
        @appendComment()
        @currentParentEl = @previousParentEls.pop()

        @level--
        @appendText(@indentText(), 'whitespace')
        @appendText(value, tag) # append `)`
        @comment += Formatter.comments[tag]
        @appendComment()

        @currentParentEl = @previousParentEls.pop()
      else if tag is 'CHAR_GROUP_START'
        @appendText(value, tag)
      else if tag is 'CHAR_GROUP'
        @appendText(value, tag)
        @comment += Formatter.comments[tag]
      else if tag is 'CHAR_GROUP_END'
        @appendText(value, tag)
      else if tag is 'OR'
        @appendComment()
        newParentEl = document.createElement 'div'
        newParentEl.className = 'or'
        @currentParentEl.appendChild(newParentEl)
        @previousParentEls.push(@currentParentEl)
        @currentParentEl = newParentEl
        @appendText(@indentText(), 'whitespace')
        @appendText(value, tag) # append `|`
        @comment += Formatter.comments[tag]
        @appendComment()
        @currentParentEl = @previousParentEls.pop()
        @appendText(@indentText(), 'whitespace')
      else if tag is 'SPECIAL'
        @appendText(value, tag)
      else if tag is 'WHITESPACE'
        @appendText(value, tag)
      else if tag is 'ESCAPED'
        @appendText(value, tag)
      else if tag is 'ESCAPED_DOLLAR'
        @appendText(value, tag)
      else if tag is 'RANGE'
        @appendText(value, tag)
        @comment += Formatter.comments[tag]
      else if tag is ''
        @appendText(value, tag)

    return @formattedEl
