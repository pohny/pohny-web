define (require) ->
  Backbone = require 'backbone'
  Marionette = require 'backbone.marionette'
  Val = require 'helpers/validate'
  DateHelper = require 'helpers/date-helper'
  _ = require 'underscore'
  mic = require 'helpers/mic'

  require 'twilio' # import Twilio
  exports = {}

  class CalledView extends Marionette.ItemView
    template: '#called-template'
    className: 'pure-g'

  class CallingView extends Marionette.ItemView
    template: '#calling-template'
    className: 'pure-g'

  class VoiceView extends Marionette.View
    template: '#contact-template'
    modelEvents:
      change: 'render'
    tagName: 'li'
    className: 'pure-menu-item'

  class VoiceLayout extends Marionette.LayoutView
    template: '#voice-layout'
    id: 'voice-content'

  class VoiceManager
    constructor: (@app, @dataSource) ->
      Twilio.Device.ready (device) -> trace "Client is ready"
      Twilio.Device.error (error) -> trace "Error", error
      Twilio.Device.disconnect (conn) =>
        trace 'call Ended'
        Twilio.Device.disconnectAll()
        @app.conn = null
        @updateOnGoingCall('null')
      Twilio.Device.connect (conn) =>
        @app.conn = conn
        trace 'calling', conn.message.PhoneNumber
        @updateOnGoingCall(conn.message.PhoneNumber)
        #conn.sendDigits("0")
      Twilio.Device.incoming (conn) =>
        trace 'call coming in!'
        @app.conn = conn
        view = new CalledView( {
          model: new Backbone.Model({ from: conn.parameters.From})
          events:
            'click #accept-call': @getAcceptCall(@)
            'click #reject-call': @getRejectCall(@)
        })
        view.render()
        @app.resources.popup.open(view)
      Twilio.Device.setup(@dataSource.user.capabilityToken)
      trace 'phone setting up ...', @dataSource.user.capabilityToken


    # TODO: this function and CallingView are global to the app, maybe move them in app scope ?
    updateOnGoingCall: (target) ->
      if @app.conn
        view = new CallingView({
          model: new Backbone.Model({target: target})
          events:
            'click .hangup': @getHangup(@)
        })
        view.render()
        @app.stickyRegion.show view
      else
        @app.stickyRegion.$el.html('')
      if @layout then @updateSticky()

    getAcceptCall: (ctx) ->
      return () ->
        # for some reason using mic below prevent connection to the call
        #mic(ctx.app.conn.mediaStream.stream)
        ctx.app.conn.accept()
        ctx.app.resources.popup.close()
        ctx.updateOnGoingCall(ctx.app.conn.parameters.From)

    getRejectCall: (ctx) ->
      return () ->
        ctx.conn.reject()
        ctx.resources.popup.close()

    updateSticky: () ->
      if @app.conn
        @app.stickyRegion.$el.hide()
        @layout.$el.find('.phone .docall').hide()
        @layout.$el.find('.phone .hangup').show()
      else
        @layout.$el.find('.phone .docall').show()
        @layout.$el.find('.phone .hangup').hide()

    renderVoice: () ->
      @updateSticky()
      @layout.$el.find('#dial').focus()
      mic()

    @schema:
      phone: Val.String().required().regex(/^\+(?:[0-9] ?){6,14}[0-9]$/) #phone number

    getCall: (ctx) ->
      (e) ->
        phoneNumber = $('#dial').val()
        try
          Val.one(phoneNumber, VoiceManager.schema.phone)
          ctx.app.call(phoneNumber)
        catch e
          trace "Invalid phone Number", e



    getHangup: (ctx) ->
      (e) ->
        #ctx.app.sendMessage 'hangup', [callSid]
        Twilio.Device.disconnectAll()


    getSendDigit: (ctx) ->
      (e) ->
        if ctx.app.conn
          el = ctx.layout.$el.find('#dial')
          value = el.val()
          if value.length > 0
            char = value[value.length-1]
            try
              ctx.app.conn.sendDigits(char)

    render: () ->
      @layout = new VoiceLayout( {
        events:
          'click .docall': @getCall(@)
          'click .hangup': @getHangup(@)
          'keyup #dial': @getSendDigit(@)
          'keypress #dial': (e) ->
            # accept directional keys, backspace, #, *, +, and Numbers
            # TODO: Display + by default as I only support E.164 format
            # TODO: could be nice to have a flag list like hangout for country prefix
            if [0, 8, 32, 35, 42, 43].indexOf(e.which) > -1 then return
            if e.which < 48 || e.which > 57 then e.preventDefault()

      })
      @layout.render()
      @app.show(@layout, () => @renderVoice())
      #@layout.getRegion('content').show(new VoiceView( {})

  exports = {}
  exports.Manager = VoiceManager
  return exports
