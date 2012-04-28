express = require 'express'

configure = require './lib/configure'
routes = require './lib/routes'

app = express.createServer()
app.configure = configure.defaults
app.configure 'development', configure.development

app.get '/danielle', routes.get_danielle
app.get '/jim', routes.get_jim

app.listen port = 80
console.log "listening on :#{port}"
