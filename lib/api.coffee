mongoose = require 'mongoose'
async    = require 'async'
_        = require 'underscore'
moment   = require 'moment'

schemas  = require './schemas'

connection = mongoose.createConnection(env?.MONGO_URL or 'mongodb://localhost/bus')

{ Route, Stop, StopTimes } = schemas.createSchemas connection

EARTH_RADIUS = 6367.5 # Mean radius for Iceland in km


WEEKDAYS = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']

HOLIDAYS = {
    '2013-03-28': 'sun', # Skírdagur
    '2013-03-29': 'sun', # Föstudagurinn langi
    '2013-04-01': 'sun', # Annar í páskum
    '2013-05-01': 'sun', # Fyrsti maí
    '2013-06-17': 'sat'  # Sautjándi júní
}

@dayOfWeek = dayOfWeek = (date) ->
    iso = (moment date).format 'YYYY-MM-DD'
    if iso of HOLIDAYS
        return HOLIDAYS[iso]

    WEEKDAYS[date.getDay()]

transformStop = (s) ->
    stop = s.toObject()
    [lng, lat] = stop.location
    stop.location = [lat, lng]
    delete stop['_id']
    return stop

transformStopTimes = (timeFilter) -> (st) ->
    endStop = transformStop st.endStop
    stop = transformStop st.stop

    route: Number st.route
    times: _(st.times).filter timeFilter
    source: st.source
    endStop: endStop
    stop: stop

createTimeFilter = (options={}) ->
    { from, to }  = options

    toTime = (t) ->
        [h, m] = t.split ':'
        time = from.clone()
        time.hours(h).minutes(m)
        if h is '00'
            time.add 'days', 1

        return time

    (t) -> from < (toTime t) < to

@nearest = (latitude, longitude, options, callback) ->
    opts = _.defaults options,
        radius: 500 # meters

    distance = (opts.radius / 1000) / EARTH_RADIUS

    Stop.find { location: { $nearSphere: [longitude, latitude], $maxDistance: distance } }, (err, stops) ->
        callback null, stops.map transformStop

@nearestRoutes = (latitude, longitude, options, callback) ->
    opts = _.defaults options,
        from: moment().startOf 'day'
        to: moment().endOf('day').add('hours', 2)
        radius: 500 # meters

    date = opts.from.toDate()
    distance = (opts.radius / 1000) / EARTH_RADIUS

    StopTimes.find { 'stop.location': { $nearSphere: [longitude, latitude], $maxDistance: distance }, days: dayOfWeek date }, (err, times) ->
        callback null, _(times).chain().map(transformStopTimes createTimeFilter(opts)).filter((t) -> t.times.length > 0).value()

stopsCache = undefined
@stops = (callback) ->
    if stopsCache is undefined
        Stop.find().sort('longName', 'ascending').exec (err, stops) ->
            stopsCache = stops.map transformStop
            callback null, stopsCache

    else
        callback null, stopsCache

stoppedyStop = @stop = (stopId, options, callback) ->
    opts = _.defaults options,
        from: moment().startOf 'day'
        to: moment().endOf('day').add('hours', 2)

    date = opts.from.toDate()

    Stop.findOne { stopId: stopId }, (err, stop) ->
        unless stop
            callback new Error 'This bus stop doesn\'t exist'
            return

        StopTimes.find { 'stop.stopId': stopId, days: dayOfWeek date }, (err, stopTimes) ->
            callback null, stopTimes.map transformStopTimes createTimeFilter(opts)

transformBetween = (r) ->
    from = transformStop r.fromStop
    to = transformStop r.toStop
    endStop = transformStop (_ r.route.stops).last()

    route: Number r.route.route
    from: from
    to: to
    endStop: endStop

@between = (from, to, options, callback) ->
    if (_ options).isFunction()
        callback = options
        options = {}

    opts = _.defaults options,
        radius: 500 # meters

    distance = (opts.radius / 1000) / EARTH_RADIUS

    routes = (l) -> (callback) -> Route.find { "stops.location": { $nearSphere: [l.longitude, l.latitude], $maxDistance: distance } }, callback
    stops = (l) -> (callback) -> Stop.find { location: { $nearSphere: [l.longitude, l.latitude], $maxDistance: distance } }, 'stopId', callback

    async.parallel { fromRoutes: routes(from), fromStops: stops(from), to: stops(to) }, (err, res) ->
        uniqueRoutes = (_ res.fromRoutes).uniq false, (r) -> r.id

        fromStopIds = (_ res.fromStops).pluck 'stopId'
        toStopIds = (_ res.to).pluck 'stopId'

        routes = (_ uniqueRoutes).map (r) ->
            stopIds = (_ r.stops).map (s) -> s.stopId

            fromStop = (_ fromStopIds).find (s) -> s in stopIds
            toStop = (_ toStopIds).find (s) -> s in stopIds

            fromIdx = stopIds.indexOf fromStop
            toIdx = stopIds.indexOf toStop

            route: r
            fromStop: r.stops[fromIdx]
            toStop: r.stops[toIdx]
            fromIdx: fromIdx
            toIdx: toIdx

        callback undefined, (_ (_ routes).filter (r) -> r.fromIdx < r.toIdx).map transformBetween

@betweenWithTimes = (from, to, options, callback) ->
    if (_ options).isFunction()
        callback = options
        options = {}

    process = (route, callback) ->
        stoppedyStop route.from.stopId, {}, (err, stop) ->
            times = (_ stop).find (r) -> r.route is route.route and r.endStop.stopId is route.endStop.stopId
            route.times = times.times
            route.source = times.source
            callback undefined, route

    @between from, to, options, (err, routes) ->
        async.map routes, process, (err, routes) ->
            callback undefined, routes
