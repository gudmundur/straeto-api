api = require '../lib/api'
_ = require 'underscore'

sprettur = {latitude: 64.14543372556909, longitude: -21.928324699401855}
petar = {latitude: 64.14941970903878, longitude: -21.97789192199707}
gundi = {latitude: 64.13199318917611, longitude: -21.910085678100586 }

describe 'Route', ->
    it 'should find routes 11 and 13 from work to Petars place', (done) ->
        api.between sprettur, petar, (err, routes) ->
            routeNrs = (_ routes).map (r) -> Number r.route.route

            expect(routeNrs).to.have.length 2
            expect(routeNrs).to.include 11
            expect(routeNrs).to.include 13

            done()

    it 'should find route 13 from Gundis place to work', (done) ->
        api.between gundi, sprettur, (err, routes) ->
            routeNrs = (_ routes).map (r) -> Number r.route.route

            expect(routeNrs).to.have.length 4
            expect(routeNrs).to.include 13

            done()