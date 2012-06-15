vows    = require 'vows'
assert  = require 'assert'

api     = require '../lib/api'

vows.describe('Nearest').addBatch 
    'when at Austurvöllur':
        topic: ->
            someday = moment. ... # point of time for test
            api.nearest someday, 64.14753259999999, -21.9385416, @callback
            return

        'the nearest stops are MR, Ráðhúsið and Lækjartorg': (err, nearest) ->
            console.log nearest

        'the busses that stop there are ...': (err, nearest) ->

    
.export module
