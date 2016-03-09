module.exports = (env) ->
  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'
  _ = env.require 'lodash'
  M = env.matcher

  request = require 'request'
  querystring = require "querystring"

  class QuoteOfTheDay extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      env.logger.info("Quote of the day started")

      deviceConfigDef = require("./device-config-schema.coffee")

      @framework.deviceManager.registerDeviceClass("QuoteDevice", {
        configDef: deviceConfigDef.QuoteDevice,
        createCallback: (config) -> new QuoteDevice(config)
      })

      @framework.ruleManager.addActionProvider(
        new QuoteDeviceModeActionProvider(@framework)
      )

  class QuoteDevice extends env.devices.Device
    attributes:
      quote:
        description: "the quote"
        type: "string"
      author:
        description: "the quote author"
        type: "string"
      url_encoded_quote:
        description: "the URL encoded quote"
        type: "string"

    constructor: (@config) ->
      @id = config.id
      @name = config.name
      @_quote = ""
      @_author = ""
      @_url_quote = config.quote
      super()
      @getHttpQuote()
      @getQuote()

    getHttpQuote: () ->
      # request "http://quotes.rest/qod.json", (error, response, body) =>
      #   if (!error && response.statusCode == 200)
      #     data = JSON.parse(body)
      #     if data.contents?
      #       @setQuote data.contents.quotes[0].quote
      #       @setAuthor data.contents.quotes[0].author
      new Promise( (resolve, reject) =>
        request "http://catfacts-api.appspot.com/api/facts", (error, response, body) =>
          if (!error && response.statusCode == 200)
            data = JSON.parse(body)
            env.logger.info("update...")
            if data.facts?
              @setQuote data.facts[0]
              @setAuthor data.facts[0]
              resolve data
            else
              reject "Unexpected response. :("
          else
            reject error.message ?
              "Was expecting status code 200 but got" + response.statusCode
      )

    setQuote: (quote) ->
      @_quote = quote
      this.setUrl_encoded_quote(quote)
      @emit "quote", @_quote

    getQuote: () ->
      Promise.resolve(@_quote)

    setAuthor: (author) ->
      @_author = author
      @emit "author", @_author

    getAuthor: () ->
      Promise.resolve(@_author)

    setUrl_encoded_quote: (quote) ->
      @_url_quote = quote
      @emit "url_encoded_quote", querystring.escape(@_url_quote)

    getUrl_encoded_quote: () ->
      Promise.resolve(@_url_quote)

  class QuoteDeviceModeActionProvider extends env.actions.ActionProvider

    constructor: (@framework) ->

    parseAction: (input, context) =>
      retVar = null

      quotes = _(@framework.deviceManager.devices).values().filter(
        (device) -> device.hasAttribute("quote")
      ).value()

      if quotes.length is 0 then return

      device = quotes[0]
      valueTokens = ['now']
      match = null

      # Try to match the input string with:
      M(input, context).match('update quote ')
        .matchDevice(quotes, (next, d) ->
          console.log('matched')
          m = next.match(' with ')
            .matchStringWithVars( (next, ts) ->
              console.log('matched 2')
              m = next.match(' mode', optional: yes)
              if device? and device.id isnt d.id
                context?.addError(""""#{input.trim()}" is ambiguous.""")
                return

              device = d
              valueTokens = ts
              console.log(m.getFullMatch())
              match = m.getFullMatch()
            )
          )

      if match?
        console.log('we got a match <3')
        if valueTokens.length is 1 and not isNaN(valueTokens[0])
          value = valueTokens[0]
          assert(not isNaN(value))
          modes = ["now"]
          if modes.indexOf(value) < -1
            context?.addError("Allowed modes: now")
            return
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new QuoteDeviceActionHandler(
            @framework, device, valueTokens
          )
        }
      else
        return null

  class QuoteDeviceActionHandler extends env.actions.ActionHandler
   
    constructor: (@framework, @device, @valueTokens) ->
      assert @device?
      assert @valueTokens?

    _doExecuteAction: (simulate, value) =>
      new Promise( (resolve, reject) =>
        if simulate
          resolve "would set mode of" + @device.name
        else
          @device.getHttpQuote()
          .then( =>
            resolve "updated quote to " + @device.quote
          )
          .catch( (error) ->
            reject if error instanceof Error then error else new Error(error)
          )
      )

    executeAction: (simulate, value) =>
      console.log('hierkom ik2')
      return @_doExecuteAction(simulate, value)

    hasRestoreAction: -> yes
    executeRestoreAction: (simulate) =>
      Promise.resolve(@_doExecuteAction(simulate))

  quote = new QuoteOfTheDay
  return quote