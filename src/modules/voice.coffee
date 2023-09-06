define (require) ->
  Backbone = require 'backbone'
  Marionette = require 'backbone.marionette'
  Val = require 'helpers/validate'
  DateHelper = require 'helpers/date-helper'
  _ = require 'underscore'
  mic = require 'helpers/mic'

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
      device = @app.resources.device
      device.on('registered', () -> trace "Client is registered")
      device.on('error', () ->
        trace "Error", error
        @updateOnGoingCall('null')
      )

      device.on('unregistered', () =>
        trace 'call Ended'
        device.disconnectAll()
        @app.myCall = null
        @updateOnGoingCall('null')
      )

      device.on('incoming', (call) =>
        trace 'call coming in!'
        @app.myCall = call
        view = new CalledView( {
          model: new Backbone.Model({ from: call.parameters.From})
          events:
            'click #accept-call': @getAcceptCall(@)
            'click #reject-call': @getRejectCall(@)
        })
        view.render()
        @app.resources.popup.open(view)
      )
      device.register()

      trace 'phone setting up ...', @dataSource.user.capabilityToken


    # TODO: this function and CallingView are global to the app, maybe move them in app scope ?
    updateOnGoingCall: (target) ->
      if @app.myCall
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
        #mic(ctx.app.myCall.mediaStream.stream)
        ctx.app.myCall.accept()
        ctx.app.resources.popup.close()
        ctx.updateOnGoingCall(ctx.app.myCall.parameters.From)

    getRejectCall: (ctx) ->
      return () ->
        ctx.app.myCall.reject()
        ctx.app.resources.popup.close()

    updateSticky: () ->
      if @app.myCall
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
          ctx.updateOnGoingCall(phoneNumber)
          ctx.app.call(phoneNumber)
        catch e
          trace "Invalid phone Number", e



    getHangup: (ctx) ->
      (e) ->
        device = ctx.app.resources.device
        device.disconnectAll()
        ctx.app.myCall = null
        ctx.updateOnGoingCall('null')


    getSendDigit: (ctx) ->
      (e) ->
        if ctx.app.myCall
          el = ctx.layout.$el.find('#dial')
          value = el.val()
          if value.length > 0
            char = value[value.length-1]
            try
              ctx.app.myCall.sendDigits(char)

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
