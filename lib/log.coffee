mongoose = require 'mongoose'

LocationLogSchema = new mongoose.Schema { created: { type: Date, default: Date.now } }, { strict: false }

exports.createLogger = (connection) ->
    logger = connection.model 'LocationLog', LocationLogSchema

    (obj) => 
        logger.create obj, (err, res) ->
            console.log err
            console.log res