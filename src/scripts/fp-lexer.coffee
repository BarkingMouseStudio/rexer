tokenRegex =
  SPECIAL_CHAR: /^\\[wWdDsSbB]/
  WHITESPACE_CHAR: /^\\[tnr]/
  ESCAPED_CHAR: /^\\./
  INPUT_START: /^\^/
  INPUT_END: /^\$/
  ESCAPED_DOLLAR: /^\${2}/
  QUANTIFIER: /^(?:(\?)|([\+\*]\??))/
  GROUP_START: /^\((\?(?:(?:\:)|(?:\=)|(?:\!)|(?:\<\=)|(?:\<\!))?)?/
  GROUP_END: /^\)/
  OR: /^\|/
  RANGE: /^\{(?:(\d*,\d+)|(\d+,\d*))\}/
  CHAR_GROUP: /^(\[\^?)((?:\\\]|.)+?)\]/
  OTHER: /^[^\#\(\)\|\[\]\?\+\*\^\$\\\s*]+/
  WHITESPACE: /^\s+/
  COMMENT: /^\ \#\ (.*)\s*$/m

tokenPriority = [
  'WHITESPACE'
  'SPECIAL_CHAR'
  'WHITESPACE_CHAR'
  'ESCAPED_CHAR'
  'INPUT_START'
  'ESCAPED_DOLLAR'
  'INPUT_END'
  'QUANTIFIER'
  'GROUP_START'
  'GROUP_END'
  'OR'
  'RANGE'
  'CHAR_GROUP'
  'COMMENT'
  'OTHER'
]

blacklistedTokens = [
  'WHITESPACE'
]

memoize = (fn) ->
  memo = {}
  (key) ->
    memo[key] = fn key unless memo[key]?
    memo[key]

slice = (arr) ->
  Array::slice(arr)

push = (stack, item) ->
  [item].concat stack

exec = (regexp, str) ->
  regexp.exec str

first = (arr) ->
  arr[0]

slice = (arr, from, to) ->
  Array::slice(arr, from, to)

chunk = (str, len) ->
  str[len..]

compose = (f, g) ->
  (x) ->
    f(g(x))

length = (a) ->
  a.length

ifelse = (testFn, trueCb, falseCb) ->
  (subject) ->
    if result = testFn(subject) then trueCb(result) else falseCb(result)

bind = (fn, cont) ->
  (subject) ->
    [value, stack] = fn subject
    (cont value) subject

unit = (a) ->
  [a]

result = (value) ->
  (subject) ->
    [value, subject]

tok = (str) ->
  match = exec(Lexer.tokenRegex[tokenKind], str)
  chunk(str, length(first(match)))

tokenize = (str) ->
  if match = exec(Lexer.tokenRegex[tokenKind], str)
    return [str, []]
  [chunk(str, length(first(match))), [tokenKind, matchedText]]
