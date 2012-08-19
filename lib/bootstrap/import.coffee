path       = require 'path'
fs         = require 'fs'
crypto     = require 'crypto'

mongoose   = require 'mongoose'
csv        = require 'csv'
async      = require 'async'
_          = require 'underscore'

routes     = require 'straeto-scraper/routes'

schemas    = require '../schemas'

connection = mongoose.createConnection(env?.MONGO_URL or 'mongodb://localhost/bus')

{ Stop, Route, ScrapedRoute, ScrapedTrip } = schemas.createSchemas connection

importStops = (file, callback) ->
    csv()
    .fromPath(file)
    .on 'data', ([stopId, longName, shortName, latitude, longitude], index) ->
        return if index is 0
        s = new Stop
            stopId: stopId
            longName: longName
            shortName: shortName
            location: [longitude, latitude]

        s.save()

    .on 'end', (count) ->
        callback null, count

parseName = (file) ->
    m = path.basename(file, '.csv').split '-'
    
    route: Number m[0]
    variant: m[3]
    file: file

importRoute = (file, callback) ->
    stopIds = []
    route = new Route(parseName file)

    csv()
    .fromPath(file)
    .on 'data', ([stopId, longName, shortName, latitude, longitude], index) ->
        stopIds.push stopId

    .on 'end', ->
        async.map stopIds, ((stopId, cb) -> Stop.findOne({ stopId: stopId}, cb)), (err, stops) ->
            route.stops = stops
            [first, between..., last] = stops
            route.from = first.longName
            route.to = last.longName

            route.save((err, res) -> 
                if err
                    console.log route
                    console.log err

                callback err, route
            )

tripSignature = (trip) ->
    key = "#{trip.route}-#{trip.direction}-#{trip.stops.join ','}"
    return (crypto.createHash 'sha1').update(key).digest('hex')

importFromScraper = (callback)->
    routes.on 'route', (route) ->
        console.log "Scraping route #{route.route}"
        sr = new ScrapedRoute route
        sr.save()

    routes.on 'trip', (route, direction, days, trip) ->
        stops = _(trip).pluck 'stop'
        times = _(trip).pluck 'time'

        st = new ScrapedTrip
            route: route
            direction: direction
            days: days
            stops: stops
            times: times

        st.signature = tripSignature st

        st.save()
          
    routes.on 'end', ->
        routes.removeAllListeners()
        callback null

    routes.scrape()

stepImportStops = (callback) ->
    Stop.collection.drop ->
        importStops 'data/stops/allStops.csv', (err, count) ->
            return callback err if err
            console.log "Importing all stops -> #{count} stops"
            callback null

stepImportRoutes = (callback) ->
    Route.collection.drop ->
        fs.readdir 'data/stops', (err, files) ->
            importFile = (file, callback) ->
                importRoute path.join('data/stops', file), (err, res) ->
                    console.log "Importing stops for #{file}"
                    callback null
 
            async.forEach _(files).without('allStops.csv'), importFile, callback

stepImportFromScraper = (callback) ->
    ScrapedRoute.collection.drop ->
        ScrapedTrip.collection.drop ->
            importFromScraper ->
                callback null

closeConnections = -> connection.close()

async.waterfall [
    stepImportStops,
    stepImportRoutes,
    stepImportFromScraper
], (err, res) ->
    console.log err if err
    connection.close()

