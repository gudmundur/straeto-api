mongoose = require 'mongoose'

schemas  = require './schemas'

connection = mongoose.createConnection(env?.MONGO_URL or 'mongodb://localhost/bus')

{ Stop } = schemas.createSchemas connection

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
