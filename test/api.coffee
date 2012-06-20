vows    = require 'vows'
assert  = require 'assert'
moment  = require 'moment'

api     = require '../lib/api'

vows.describe('api').addBatch 
    'when at Austurvöllur':
        topic: ->
            someday = moment() # TODO point of time for test
            api.nearest someday, 64.14753259999999, -21.9385416, @callback
            return

        'the nearest stops are MR, Ráðhúsið and Lækjartorg': (err, nearest) ->
            #console.log nearest

        'the busses that stop there are ...': (err, nearest) ->

    'when querying for a non existing stop':
        topic: ->
            api.stop '123', new Date(), @callback
            return
    
        'an error is returned': (err, stop) ->
            assert.isNotNull err
            assert.isUndefined stop

    'when querying for Laugarnestangi':
        topic: ->
            api.stop '90000162', new Date(), @callback
            return

        'that *no* error occurred': (err, stop) -> assert.isNull err
        'only route 12 stops': (err, stop) ->
            assert.lengthOf stop.routes, 1
            assert.equal stop.routes[0].route, 12

    'when querying for MR':
        topic: ->
            api.stop '90000004', new Date(), @callback
            return

        'that *no* error occurred': (err, stop) -> assert.isNull err
        'that 7 different routes stop': (err, stop) ->
            assert.lengthOf stop.routes, 7

    'when querying for Hlemmur':
        topic: ->
            api.stop '90000295', new Date(), @callback
            return

        'that *no* error occurred': (err, stop) -> assert.isNull err
        'that route 6 has 3 different end stops': (err, stop) ->
            route = (s for s in stop.routes when s.route == 6)
            assert.lengthOf route, 3

        'that 14 different routes stop in both directions (all in all 29)': (err, stop) ->
            assert.lengthOf stop.routes, 29




.export module
