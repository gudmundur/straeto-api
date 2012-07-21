express = require 'express'
app     = express.createServer()

env     = process.env

api     = require './lib/api'

# Setup configuration
app.use express.errorHandler { showStacktrace: true, dumpExceptions: true }
app.use express.logger format: ':method :url :remote-addr'
app.use express.bodyParser()
app.use express.static(__dirname + '/public')
app.set 'view engine', 'jade'
app.enable 'jsonp callback'


app.get '/api/stops/:id', (req, res) ->
    api.stop req.params.id, new Date(), (err, stop) -> 
        if err
            res.send 404
            return

        res.json stop

app.get '/api/stops/', (req, res) ->
    api.stops (err, stops) ->
        res.json stops

# TODO: Rename this to /api/stops?near=latlng
app.get '/api/nearest', (req, res) ->
    { latitude, longitude } = req.query
    api.nearest latitude, longitude, (err, nearest) -> res.json nearest

# Listen
port = env?.PORT or 3000
app.listen port 
console.log "Express server listening on port #{port}"
