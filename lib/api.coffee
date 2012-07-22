mongoose = require 'mongoose'

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
