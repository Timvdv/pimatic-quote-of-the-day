module.exports = (env) ->
  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  request = require 'request'
  querystring = require "querystring"

  class QuoteOfTheDay extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      env.logger.info("Quote of the day started")

      deviceConfigDef = require("./device-config-schema.coffee")

      @framework.deviceManager.registerDeviceClass("QuoteDevice", {
        configDef: deviceConfigDef.QuoteDevice, 
        createCallback: (config) => new QuoteDevice(config)
      })

  class QuoteDevice extends env.devices.Device
    attributes:
      quote:
        description: "the quote"
        type: "string"
      url_encoded_quote:
        description: "the URL encoded quote"
        type: "string"

    constructor: (@config) ->
      @id = config.id
      @name = config.name
      @_quote = config.quote
      @_url_quote = config.quote
      super()
      @getHttpQuote()
      @getQuote()
      @getUrl_encoded_quote("Kaas is een lekkere groente")

    getHttpQuote: () ->
      request "http://catfacts-api.appspot.com/api/facts", (error, response, body) =>
        if (!error && response.statusCode == 200)
          data = JSON.parse(body)
          if data.facts?
            @setQuote data.facts[0]

    setQuote: (quote) ->
      @_quote = quote
      @emit "quote", @_quote

    getQuote: () ->
      Promise.resolve(@_quote)

    setUrl_encoded_quote: (quote) ->
      @_url_quote = quote
      @emit "url_encoded_quote", querystring.escape(@_url_quote)

    getUrl_encoded_quote: () ->
      Promise.resolve(querystring.escape(@_url_quote))


  quote = new QuoteOfTheDay
  return quote