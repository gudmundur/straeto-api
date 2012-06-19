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

        'only route 12 stops': (err, stop) ->
            assert.isNull err
            assert.lengthOf stop, 1
            assert.equal stop[0].route, 12

    'when querying for MR':
        topic: ->
            api.stop '90000004', new Date(), @callback
            return

        'that 7 different routes stop': (err, stop) ->
            assert.isNull err
            assert.lengthOf stop, 7


.export module
