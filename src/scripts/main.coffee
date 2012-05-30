workarea = CodeMirror document.getElementById('workarea'),
  value: '''
    /// http:\/\/(\\w+)\/ ///gi
    '''
  mode:  'rexer'
  lineWrapping: true
  autofocus: true
  tabindex: 0
  autoClearEmptyLines: true
  tabSize: 2
  lineNumbers: true
  theme: 'rexer'
  onChange: ->
    testarea.highlightMatches(workarea.getValue())

testarea = CodeMirror document.getElementById('testarea'),
  value: 'http://applio.us/\nhttp://asdasd/\nhttps://mail.google.com/'
  mode: 'plaintext'
  lineWrapping: true
  tabindex: 1
  tabSize: 2
  onChange: ->
    testarea.highlightMatches(workarea.getValue())

testarea.highlightMatches(workarea.getValue())

workarea.autoFormatRange(workarea.posFromIndex(0), workarea.posFromIndex(workarea.getValue().length))
workarea.refresh()
