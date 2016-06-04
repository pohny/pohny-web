define (require) ->
  Backbone = require 'backbone.marionette'
  Twilio = require 'twilio'
  resources = {}

  window.NODE_ENV = 'dev'
  window.trace = resources.trace = () ->
    if window.NODE_ENV == 'dev'
      console.log if arguments.length > 1 then arguments else arguments[0]

  ### ---- define the pop up properties ---- ###
  Modal =  Marionette.Region.extend({
    initialize: () ->
      self = this
      $(this.el).find('.modal-overlay').click(() -> self.close())
      $(this.el).find('.close').click(() -> self.close())
    el: '#modal'
    open: (view) ->
      this.$el.find('.modal-content').empty().append(view.el)
      @show()
    show: () -> this.$el.fadeIn(200)
    close: () -> this.$el.fadeOut(200)
  })
  resources.popup = new Modal()


  resources.menus =
    #menu: "M3 18h18v-2H3v2zm0-5h18v-2H3v2zm0-7v2h18V6H3z"
    #contacts: "M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"
    'contacts/new':
      name: 'contacts-new'
      svg: "M9 17c0-3 2-6 5-7 0-1 .5-2 .6-2.7C15 3 15 0 10.5 0S6 3 6 6.7c0 2.3 1.3 4.6 3 5.5v1c-5 .4-9 3-9 6h9C9 19 9 18 9 17zM17.25 10.5c-4 0-7 3-7 7S13.5 24 17 24 24 21 24 17.25s-3-6.7-6.7-6.7zM21 18h-3v3h-1.5v-3h-3v-1.5h3v-3H18v3h3V18z"
    contacts:
      svg: "M4.5 0v24h18V0h-18zm9 6c2 0 3 1.5 3 3 0 1.6-1.3 3-3 3-1.6 0-3-1.3-3-3 0-1.6 1.3-3 3-3zM18 18h-9v-1.5c0-1.6 1.3-3 3-3h3c1.6 0 3 1 3 3V18zM1.5 1.5h2V6h-2V1.5zm0 6h2V12h-2V7.5zm0 6h2V18h-2v-4.5zm0 6h2V24h-2v-4.5z"
    conversations:
      #svg: "M20 2H4c-1.1 0-1.99.9-1.99 2L2 22l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM6 9h12v2H6V9zm8 5H6v-2h8v2zm4-6H6V6h12v2z"
      svg:"M10 4c-3.2.3-7.3 2-7.3 5.5.1 1.8 1.2 3.2 2.5 4.1.8.7 1 1.35 1.2 2.25.6-.6 1.4-.8 2-1 1.55.18 3.25.0 4.6-.4 2.2-.8 4.23-2.8 4.3-5-.5-3.7-4.1-5.5-7.3-5.5zm0-2.77c5.5 0 10 3.7 10 8.25-1 6.8-6.7 8.5-11.5 8.1-2.1 2.2-4.6 2.6-7.1 2.6 1.7-1.66 2.4-2.2 2.4-3.8C1.7 14.5.1 12.16 0 9.5c0-4.5 4.5-8.2 10-8.2zm13 22c-2.15-0-4.4-.43-6.3-2.3-2.5.3-5-.5-7-1.7 3-0 5.4.25 9-3.3 3.2-3.5 2.7-6.45 2.7-8 3.3 3.7 3.5 8.7-.7 11.5-.7 1.7 1.2 2.8 2.2 3.87z"

    voice:
      svg: "M18 14C16 16 16 18 14 18s-3.2-1.6-4.8-3.2C8 13 6 11 6 10 6 8 8 8 10 6S6 0 5 0C3 0 0 5 0 5 0 8 3.288 14.5 6 17 9.5 21 16 24 19 24c0 0 5-3 5-5 0-1.6-5-6-6-5z"

  resources.createMenus = (menus, currentMenu) ->
    out = []
    extra = null
    for k, v of menus
      extra = if currentMenu == k then ' active' else ''
      out.push _.template($('#menu-template').html())({ name: v.name || k, image: v.svg, route: k, extra: extra })
    $('#menu').html out.join("\n")
    #$('#content').html out.join("\n")



  #resources.twilio = { initalized: false}
  resources.initializePhone = () ->
    $.ajax('/token').done (token) ->
      Twilio.Device.setup(token)
      trace 'phone enabled'
    Twilio.Device.connect (conn) ->
      window.conn = conn
      window.stream = conn.mediaStream.stream
      trace 'calling'
      #conn.sendDigits("0")
    Twilio.Device.incoming (conn) ->
      conn.accept()
      window.stream = conn.mediaStream.stream
      trace 'call coming in!'

  resources.getWebsocketUri = (accessToken) ->
    protocol = 'ws'
    domain = window.location.hostname
    port = window.location.port
    protocol + '://' + domain + ':' + port + '/?token=' + accessToken


  return resources
