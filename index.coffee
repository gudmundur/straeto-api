express = require 'express'
app     = express.createServer()
env     = process.env

moment  = require 'moment'

api     = require './lib/api'

mongoose = require 'mongoose'
connection = mongoose.createConnection('mongodb://localhost/buslog')
locationLogger = (require './lib/log').createLogger connection

# Setup configuration
app.use express.errorHandler { showStacktrace: true, dumpExceptions: true }
app.use express.logger 'dev'
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

        when 'restOfDay' then return {
            from: moment().subtract 'minutes', 15
            to: moment().endOf('day').add 'hours', 2
        }

        when 'day' then return {
            from: moment().startOf 'day'
            to: moment().endOf('day').add 'hours', 2
        }

    from: if from then moment from else moment().startOf 'day'
    to: if to then moment to else moment().endOf('day').add 'hours', 2


timeRange = (req, res, next) ->
    { from, to } = buildOptions req
    req.params.from = from
    req.params.to = to
    next()

location = (req, res, next) ->
    { latitude, longitude, radius } = req.query
    req.params.latitude = latitude
    req.params.longitude = longitude
    req.params.radius = radius or 500
    next()

app.all '*', (req, res, next) ->
    res.header 'Access-Control-Allow-Origin', '*'
    next()

app.get '/stops/:id', timeRange, (req, res) ->
    api.stop req.params.id, req.params, (err, stop) ->
        if err
            res.send 404
            return

        res.json stop

app.get '/stops/', (req, res) ->
    api.stops (err, stops) ->
        res.json stops

# TODO: Rename this to /stops?near=latlng
app.get '/nearest', location, (req, res) ->
    api.nearest req.params.latitude, req.params.longitude, { radius: req.params.radius }, (err, nearest) ->
        res.json nearest

app.get '/buses', [location, timeRange], (req, res) ->
    locationLogger req.query

    api.nearestRoutes req.params.latitude, req.params.longitude, req.params, (err, times) ->
        res.json times

app.get '/between', (req, res) ->
    from = req.query.from.split ','
    to = req.query.to.split ','

    api.betweenWithTimes { latitude: from[0], longitude: from[1] }, { latitude: to[0], longitude: to[1] }, (err, routes) ->
        res.send routes

# Listen
port = env?.PORT or 3000
app.listen port
console.log "Express server listening on port #{port}"
