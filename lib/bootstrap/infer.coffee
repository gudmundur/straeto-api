csv      = require 'csv'
geolib   = require 'geolib'
_        = require 'underscore'
moment   = require 'moment'
async    = require 'async'
crypto   = require 'crypto'

mongoose = require 'mongoose'
schemas  = require '../schemas'

connection = mongoose.createConnection(env?.MONGO_URL or 'mongodb://localhost/bus')

{ Route, Trip, ScrapedRoute, ScrapedTrip } = schemas.createSchemas connection

sum = (a) -> a.reduce ((a, c) -> a + c), 0

tripSignature = (trip) ->
    key = "#{trip.route}-#{trip.direction}-#{trip.stops.join ','}"
    return (crypto.createHash 'sha1').update(key).digest('hex')

pair = (list) ->
    pairs = []
    return pairs if list.length < 2

    [first, ls..., last] = list
    previous = first
    createPair = (p, c) ->
        pairs.push [p, c]
        previous = current

    (createPair(previous, current) for current in ls)
    pairs.push [previous, last]
    
    return pairs

toLngLat = (a) -> { latitude: a[1], longitude: a[0] }
distBetweenStops = (a, b) -> 
    return 0 if a is null or b is null
    geolib.getDistance toLngLat(a.location), toLngLat(b.location)

createSegments = (knownTimes) ->
    createSegment = ([start, end]) ->
        start: start
        end: end
        duration: moment(end.time, 'HH:mm').diff moment(start.time, 'HH:mm'), 'minutes' 

    (createSegment(t) for t in pair knownTimes)

findStopsInSegment = (stops, segment) ->
    startIdx = stops.indexOf segment.start.stop
    endIdx = stops.indexOf segment.end.stop
    stops.slice startIdx, endIdx+1

processPair = (exit, enter) ->
    exit: exit
    enter: enter
    distance: distBetweenStops exit, enter

mapStops = (scrapedStops, stops) ->
    groupedStops = _(stops).groupBy (s) -> s.longName
    scrapedStops.map (s) -> groupedStops[s][0]


inferTimes = (knownTimes, allStops, callback) ->
    segments = createSegments knownTimes

    trip = []

    addTime = (stop, time) -> trip.push { stop: stop, time: time, source: 'estimated' }

    trip.push segments[0].start

    for segment in segments
        stops = findStopsInSegment allStops, segment
        pairs = (processPair(a, b) for [a, b] in pair stops)
        length = sum (p.distance for p in pairs)
        time = moment segment.start.time, 'HH:mm'

        estimateTime = (d) -> time.add('m', (segment.duration * d)/length) # This is modifying the start time in place, not good
            
        (addTime p.enter, estimateTime(p.distance).format 'HH:mm', 'estimated' for p in pairs[0..-2])
        trip.push segment.end

    callback null, trip

readSpecs = (file, callback) ->
    specs = {}

    csv()
    .fromPath(file)
    .on 'data', ([signature, spec]) ->
        specs[signature] = "data/stops/#{spec}.csv"
    .on 'end', ->
        callback null, specs 

# FIXME Routes: 
#  Route: 3, 5, 11, 19 - Same as route 6, loopety loop.
#  Route: 17, 22 - Doesn't detect the direction correctly due to a loop
#  Route: 27 - Stop data missing (only by order)

estimateTrip = (specFile, trip, callback) ->
    return unless trip and trip.stops.length > 0
    return if Number(trip.route) is 27
    
    Route.collection.findOne { file: specFile }, (err, route) ->
        return callback err if err
        return callback new Error('No matching route was given, ' + specFile) unless route

        stopNames = trip.stops
        matchedStops = (s for s in route.stops when s.longName in stopNames)
        knownTimes = ({ stop: s, time: t, source: 'scraped' } for [s, t] in _.zip mapStops(stopNames, matchedStops), trip.times)

        inferTimes knownTimes, route.stops, (err, inferred) ->
            callback err, inferred, route

inferTrip = (specs, trip, callback) ->
    specFile = specs[tripSignature trip]

    unless specFile
        # FIXME Unable to find this trip spec, probably the route changed
        console.log trip

    estimateTrip specFile, trip, (err, inferred, route) ->
        return callback err if err

        from = _(inferred).first()
        to = _(inferred).last()

        t = new Trip
            route: trip.route
            routeFile: route.file
            days: trip.days
            trip: inferred

        t.save (err) ->
            callback null, t

inferTrips = (callback) ->
    readSpecs 'specs.csv', (err, specs) ->
        infer = (trip, callback) -> inferTrip specs, trip, callback

        trips = []
        ScrapedTrip.find().stream()
        .on('data', (trip) -> trips.push trip)
        .on('error', (err) -> callback err)
        .on('close', -> 
            async.forEach trips, infer, (err) -> 
                console.log 'all done'
                callback err
        )

clearTrips = (callback) -> Trip.collection.drop (err) -> callback null

async.waterfall [
    clearTrips,
    inferTrips
], (err) ->
    console.log err if err
    console.log 'All done'
