mongoose = require 'mongoose'
_        = require 'underscore'
Hash     = require 'hashish'

schemas  = require './schemas'

connection = mongoose.createConnection(env?.MONGO_URL or 'mongodb://localhost/bus')

{ Stop, Trip, StopTimes } = schemas.createSchemas connection

@nearest = (latitude, longitude, callback) ->
    Stop.find { location: { $near: [latitude, longitude], $maxDistance: 0.004 } }, (err, stops) -> 
        console.log stops

        callback null, [
            {
                stop: {}
                routes: [
                    {
                        route: 12
                        color: 'green'

                        startstop: 'Ártún'
                        endstop: 'Skeljanes'
                        times: []
                    }
                ]
            }
        ]

        # TODO
        # 1. Which busses stop at these stops? db.trips.find({ "trip.stop.stopId": "90000184"})
        # 2. At what times are they?
 
@stop = (stopId, date, callback) -> 
    # TODO
    # 1. Find all trips that stop at this stop
    # 2. Group by route
    # 3. Extract times

    # a) Auxiliary function for decoding date to bus weekday (with holidays)

    Trip.find { 'trip.stop.stopId': stopId, 'days': 'mon' }, (err, trips) ->
        routes = Hash _(trips).groupBy (trip) -> trip.route
        mapped = routes.map (trips, route) -> 
            route: route
            times: (_(trips).map (trip) -> (_(trip.trip).find (t) -> t.stop.stopId is stopId).time).sort()

        callback null, mapped.values 
