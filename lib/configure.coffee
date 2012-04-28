path = require 'path'

express = require 'express'
stylus = require 'stylus'
eco = require 'eco'

exports.defaults = ->
  cwd = process.cwd()

  public_path = path.join(cwd, 'public')
  src_path = path.join(cwd, 'src')

  @use stylus.middleware
    debug: true
    src: src_path
    dest: public_path
    compile: (str) ->
      return stylus(str).set('compress', true)

  cookie_options =
    path: '/'
    httpOnly: true
    maxAge: day = 86400000 # 1d: (1000ms * 60s * 60m * 24hr)
    secure: true

  compiler_options =
    src: src_path
    dest: public_path
    enable: ['coffeescript']

  favicon_path = path.join(public_path, 'favicon.png')

  @use express.bodyParser()
  @use express.cookieParser()
  @use express.query()
  @use express.compiler(compiler_options)
  @use express.static(public_path)
  @use express.staticCache()
  @use express.favicon(favicon_path)

  @register '.eco', eco

  templates_path = path.join(src_path, 'templates')

  @set 'view engine', 'eco'
  @set 'view options', template_options = layout: 'layout'
  @set 'views', templates_path

exports.development = ->
  error_options =
    stack: true
    message: true
    dump: true

  @use express.errorHandler(error_options)
  @use express.logger('dev')
