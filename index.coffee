express = require 'express'
app     = express.createServer()

moment  = require 'moment'

env     = process.env

api     = require './lib/api'

# Setup configuration
app.use express.errorHandler { showStacktrace: true, dumpExceptions: true }
app.use express.logger format: ':method :url :remote-addr'
app.use express.bodyParser()
app.use express.static(__dirname + '/public')
app.set 'view engine', 'jade'
app.enable 'jsonp callback'

buildOptions = (req) ->
    { range, from, to } = req.query

    switch range
        when 'now' then return {
            from: moment().subtract 'minutes', 15
            to: moment().add 'hours', 1
        }

        when 'day' then return {
            from: moment().startOf 'day'
            to: moment().endOf('day').add 'hours', 2
        }

    from: if from then moment from else moment().startOf 'day'
    to: if to then moment to else moment().endOf('day').add 'hours', 2


app.get '/stops/:id', (req, res) ->
    options = buildOptions req

    api.stop req.params.id, options, (err, stop) ->
        if err
            res.send 404
            return

        res.json stop

app.get '/stops/', (req, res) ->
    api.stops (err, stops) ->
        res.json stops

# TODO: Rename this to /stops?near=latlng
app.get '/nearest', (req, res) ->
    { latitude, longitude } = req.query
    radius = req.query.radius or 500
    api.nearest latitude, longitude, { radius: radius }, (err, nearest) -> res.json nearest

app.get '/buses', (req, res) ->
    { latitude, longitude } = req.query
    options = buildOptions req
    options.radius = req.query.radius or 500

    api.nearestRoutes latitude, longitude, options, (err, times) ->
        res.json times

# Listen
port = env?.PORT or 3000
app.listen port
console.log "Express server listening on port #{port}"
