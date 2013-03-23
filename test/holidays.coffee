api = require '../lib/api'


describe 'Holidays', ->
    it 'should recognize the days around easter 2013', ->
        skirdagur = new Date(2013, 2, 28)
        day = api.dayOfWeek skirdagur

        expect(day).to.be.equal 'sun'

    it 'should not interfere on normal days', ->
        monday = new Date(2013, 2, 25)
        day = api.dayOfWeek monday

        expect(day).to.be.equal 'mon'
