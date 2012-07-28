mongoose = require 'mongoose'
async    = require 'async'
_        = require 'underscore'

schemas  = require './schemas'

connection = mongoose.createConnection(env?.MONGO_URL or 'mongodb://localhost/bus')

{ Stop, StopTimes } = schemas.createSchemas connection

dayOfWeek = (date) ->
    # TODO
    # a) Handling for holidays
    weekdays = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']
    weekdays[date.getDay()]

transformStop = (s) ->
    stop = s.toObject()
    delete stop['_id']
    return stop

transformStopTimes = (st) ->
    endStop = st.endStop.toObject()
    delete endStop['_id']

    route: Number st.route
    times: st.times
    source: st.source
    endStop: endStop

@nearest = (latitude, longitude, callback) ->
    Stop.find { location: { $near: [latitude, longitude], $maxDistance: 0.005 } }, (err, stops) -> 
        callback null, stops.map transformStop

@nearestRoutes = (latitude, longitude, date, callback) ->
    @nearest latitude, longitude, (err, stops) ->
        stopTimes = (stop, callback) ->
            module.exports.stop stop.stopId, date, (err, times) ->
                times.forEach (t) -> t.stop = stop
                callback err, times

        async.map stops, stopTimes, (err, times) ->
            mergeNearest = (a, b) ->
                b.forEach (t) ->
                    key = "#{t.route}-#{t.endStop.stopId}"
                    unless (_ a.seen).has key
                        a.seen[key] = true
                        a.routes.push t

                return a

            res = times.reduce mergeNearest, { seen: {}, routes: [] }
            callback null, res.routes

@stops = (callback) ->
    Stop.find().sort('longName', 'ascending').exec (err, stops) ->
        callback null, stops.map transformStop

@stop = (stopId, date, callback) -> 
    Stop.findOne { stopId: stopId }, (err, stop) ->
        unless stop
            callback new Error 'This bus stop doesn\'t exist'
            return

        StopTimes.find { 'stop.stopId': stopId, days: dayOfWeek date }, (err, stopTimes) ->
            callback null, stopTimes.map transformStopTimes
