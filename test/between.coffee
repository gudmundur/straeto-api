api = require '../lib/api'

describe 'Route', ->
    it 'aaa', (done) ->
        a = {latitude: 64.14543372556909, longitude: -21.928324699401855}
        b = {latitude: 64.14941970903878, longitude: -21.97789192199707}

        api.between { latitude: a.latitude, longitude: a.longitude }, { latitude: b.latitude, longitude: b.longitude }, (err, res) ->
            console.log res
            done()