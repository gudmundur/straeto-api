mongoose = require 'mongoose'
async    = require 'async'
_        = require 'underscore'
moment   = require 'moment'

schemas  = require './schemas'

connection = mongoose.createConnection(env?.MONGO_URL or 'mongodb://localhost/bus')

{ Stop, StopTimes } = schemas.createSchemas connection

EARTH_RADIUS = 6367.5 # Mean radius for Iceland in km

dayOfWeek = (date) ->
    # TODO
    # a) Handling for holidays
    weekdays = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']
    weekdays[date.getDay()]

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

@stops = (callback) ->
    Stop.find().sort('longName', 'ascending').exec (err, stops) ->
        callback null, stops.map transformStop

@stop = (stopId, options, callback) ->
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
