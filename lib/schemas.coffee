mongoose = require 'mongoose'

StopSchema = new mongoose.Schema
    stopId: { type: String } # index: { unique: true }}
    longName: String
    shortName: String
    location: [Number]

RouteSchema = new mongoose.Schema
    route: Number
    from: String
    to: String
    variant: Number
    file: String
    stops: [StopSchema]

StopTimeTuple = new mongoose.Schema
    stop: 
        stopId: String
        longName: String
        shortName: String
        location: [Number]
    time: String
    source: String

TripSchema = new mongoose.Schema
    route: Number
    routeFile: String
    days: [String]
    trip: [StopTimeTuple]

StopEmbeddedSchema =
    stopId: String
    longName: String
    shortName: String
    location: [Number]

StopTimesSchema = new mongoose.Schema
    route: Number
    days: [String]
    stop: StopEmbeddedSchema
    endStop: StopEmbeddedSchema
    times: [String]
    source: String

ScrapedRouteSchema = new mongoose.Schema
    route: Number
    name: String
    color: String
    url: String
    directions: Number
    main_stops: [{}]

ScrapedTripSchema = new mongoose.Schema
    route: Number
    direction: Number
    days: [String]
    stops: [String]
    times: [String]
    signature: String

RouteSchema.index { route: 1, from: 1, to: 1, variant: 1 }, { unique: true }
TripSchema.index { "trip.0.time": 1 }
StopSchema.index { location: "2d" }

exports.createSchemas = (connection) ->
    Stop: connection.model 'Stop', StopSchema
    Route: connection.model 'Route', RouteSchema
    Trip: connection.model 'Trip', TripSchema
    StopTimes: connection.model 'StopTimes', StopTimesSchema
    ScrapedRoute: connection.model 'ScrapedRoute', ScrapedRouteSchema
    ScrapedTrip: connection.model 'ScrapedTrip', ScrapedTripSchema
 
