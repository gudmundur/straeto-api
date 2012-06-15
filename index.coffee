express = require 'express'
app     = express.createServer()

env     = process.env

api     = require './lib/api'

# Setup configuration
app.use express.errorHandler { showStacktrace: true, dumpExceptions: true }
app.use express.logger format: ':method :url'
app.use express.bodyParser()
app.use express.static(__dirname + '/public')
app.set 'view engine', 'jade'
app.enable 'jsonp callback'

app.get '/api/nearest', (req, res) ->
    { latitude, longitude } = req.query
    api.nearest latitude, longitude, (err, nearest) -> console.log nearest
    res.json [
            { route: 12, color: 'green' },
            { route: 1, color: 'red' },
            { route: 2, color: 'red' },
            { route: 11, color: 'green' }
        ]

# Listen
port = env?.PORT or 3000
app.listen port 
console.log "Express server listening on port #{port}"
