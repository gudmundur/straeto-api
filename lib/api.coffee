mongoose = require 'mongoose'
_        = require 'underscore'
Hash     = require 'hashish'

schemas  = require './schemas'

connection = mongoose.createConnection(env?.MONGO_URL or 'mongodb://localhost/bus')

{ Stop, Trip, StopTimes } = schemas.createSchemas connection

@nearest = (latitude, longitude, callback) ->
    Stop.find { location: { $near: [latitude, longitude], $maxDistance: 0.004 } }, (err, stops) -> 
        callback null, (_ stops).map (s) ->
            stop = s.toObject()
            delete stop['_id']
            return stop
 
@stop = (stopId, date, callback) -> 
    # TODO
    # a) Auxiliary function for decoding date to bus weekday (with holidays)
    Stop.findOne { stopId: stopId }, (err, stop) ->
        unless stop
            callback new Error 'This bus stop doesn\'t exist'
            return

        StopTimes.find { 'stop.stopId': stopId, days: 'mon' }, (err, stopTimes) ->
            mapped = (_ stopTimes).map (st) ->
                endStop = st.endStop.toObject()
                delete endStop['_id']

                route: Number st.route
                times: st.times
                source: st.source
                endStop: endStop

            callback null,
                stop: stop
                routes: mapped
