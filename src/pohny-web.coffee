define (require) ->

  _ = require 'underscore'
  $ = require 'jquery'
  Backbone = require 'backbone'
  Marionette = require 'backbone.marionette'
  resources = require 'resources'

  Contacts = require 'modules/contact'
  Messages = require 'modules/message'
  Conversations = require 'modules/conversation'
  Voice = require 'modules/voice'

  notImplemented = () ->
    msg = '403 - ' + Backbone.history.fragment + ' not implemented'
    $("#content").html(msg)

  notifySound = new Audio('notify-message.mp3')

  class App

    myCall = null
    @mainRegion: new Marionette.Region({ el: '#content'})
    @oldRegion: new Marionette.Region({ el: '#content-old'})
    @stickyRegion: new Marionette.Region({ el: '#sticky'})

    @resources: resources

    @websocket: null
    @sendMessage: (method, params) ->
      trace method, params
      App.websocket.send( JSON.stringify({"jsonrpc": "2.0", "method": method, "params": params }) )
    @call: (phoneNumber) ->
      #ctx.app.sendMessage 'call', [phoneNumber]
      device = new Twilio.Device(@dataSource.user.capabilityToken)
      trace 'calling: ' + phoneNumber
      @myCall = await device.connect({ params: { To: phoneNumber } })
      console.log @myCall

    @show: (layout, cb) ->
      # TODO: Uncomment code below for fancy slide in effects
      ###
      left = App.mainRegion.$el.css('left')
      App.oldRegion.$el.html(App.mainRegion.$el.html())
      App.mainRegion.$el.css('left', '-110%')
      App.mainRegion.show(layout)
      if cb then cb()
      App.mainRegion.$el.animate {
        left: left
      }, 500, () ->
        App.oldRegion.$el.html('')
      ###
      App.mainRegion.show(layout)
      if cb then cb()

    @incrConversation: () ->
      if App.dataSource
        conversationUpdates = 0
        for conversation in App.dataSource.conversations.models
          if conversation.get('unread') > 0 then conversationUpdates++
        resources.createMenus(resources.menus, Backbone.history.fragment)
        if conversationUpdates > 0
          $('#menu .conversations').append('<span class="notify">' + conversationUpdates + '</span>')
        else
          $('#menu .conversations span').remove()

    @initWebsocket: (accessToken) ->
      uri = resources.getWebsocketUri(accessToken)
      #websocket = initWebsocket(App, uri)
      trace 'init websocket'
      websocket = new WebSocket(uri, "json-rpc")
      websocket.onerror = (e) ->
        trace 'Connection Error: ', e
        window.sessionStorage.removeItem('access_token')
        Authenticator.refresh()

      websocket.onclose    = (e) ->
        App.dataSource = null
        trace 'Connection Closed ' + e.code
        $('#menu').html('')
        Backbone.history.stop()
        Authenticator.refresh()
      websocket.onmessage  = (e) =>
        trace 'Received: ' + e.data
        data = JSON.parse e.data
        switch data.method
          when 'init' then App.start.apply(App, data.params)
          when 'message'
            #to = @dataSource.userData.id
            from = data.params[0]
            message = data.params[1]
            conversation = App.dataSource.conversations.get(from)
            if !conversation
              #conversation = new Conversations.ConversationModel({
              conversation = new Backbone.Model({
                name: from
                id: from
                note: ''
                unread: 1
              })
              messages = new Messages.Collection([message], {id: from })
              conversation.set 'messages', messages
              App.dataSource.conversations.add conversation
            else
              conversation.set('unread', conversation.get('unread') + 1, {silent: true} )
              conversation.get('messages').add message
            #notifySound.currentTime = 0
            notifySound.play()
            App.incrConversation()
          else trace 'unsupported command ' + data.method
      websocket.onopen     = (e) ->
        trace 'Websocket Connected'
        #clearTimeout(timeout)
        connection = e
      App.websocket = websocket


    @current = null

    #app.on "start", () ->
    @start: (conversationData, userData) ->
      #if app.NODE_ENV == 'dev'
      #  Seeds = require 'helpers/seed-data'
      #  conversationData = Seeds.getDebugContacts()

      for k, v of conversationData
        if typeof v.messages == 'string' then v.messages = JSON.parse v.messages
        v.messages = new Messages.Collection(v.messages, { id: v.id})
        v.messages.bindEvents(App)

      App.dataSource = {
        #conversations: new Backbone.Collection(_.values(conversationData))
        conversations: new Conversations.Collection(_.values(conversationData))
        #user: new Backbone.Model(user)
        user: userData
      }
      resources.device = new Twilio.Device(@dataSource.user.capabilityToken)
      document.device = resources.device

      App.dataSource.conversations.on 'all', (method, model) ->
        if ['add', 'change', 'remove'].indexOf(method) > -1
          App.sendMessage('conversations.' + method, [model.id, model.toJSON()])

      routes =
        contacts:       new Contacts.Manager(App, App.dataSource)
        conversations:  new Conversations.Manager(App, App.dataSource)
        voice:          new Voice.Manager(App, App.dataSource)
        conversation:   new Messages.Manager(App, App.dataSource)

      App.router = new Backbone.Router({
        # do some switch case with Backbone.history.fragment ?
        routes: {
          "contacts/new": () ->
            routes.contacts.render(true)

          "contact/:id": (id) ->
            conversation = App.dataSource.conversations.get(id)
            if conversation
              App.current = routes.contacts
              App.current.render(conversation)
            else App.router.navigate '404'

          "conversation/:id": (id) ->
            #console.log "Selecting conversation with " + id
            conversation = App.dataSource.conversations.get(id)
            if conversation
              App.current = routes.conversation
              App.current.render(conversation)
            else App.router.navigate '404'

          "*notFound": () ->
            routeName =  Backbone.history.fragment || 'contacts'
            App.current = routes[routeName]
            if App.current then App.current.render()
            else $('#content').html("Not Found")
        }
      })
      App.router.on "route", (route, params) ->
        App.incrConversation()
        route = Backbone.history.fragment
        menu = resources.menus[route]
        $('#sticky').show()
        if menu
          $('#menu .active').removeClass('active')
          className = if menu.name then menu.name else route
          $('#menu .' +  className).addClass('active')

        # Very simple way to refresh date for Conversation every minute
        clearInterval App.cheapInteral
        if route && Boolean(route.match(/^conversation/))
          now = new Date()
          App.lastMinute = now.getMinutes()
          App.cheapInteral = setInterval (() =>
            now = new Date()
            if App.lastMinute != now.getMinutes()
              #trace 'refresh !'
              App.lastMinute = now.getMinutes()
              App.current.refresh()
          ), 1000


      #TODO: set interval to fetch capability token
      trace 'app starting ...'
      Backbone.history.start()
      resources.createMenus(resources.menus, Backbone.history.fragment)
      App.incrConversation()


  # Init websocket connection
  #uri = base_ws_url + '/?token=' + accessToken

  ###
  interval = null
  dotsEl = document.getElementById("dots")
  startLoading = () ->
    fn = () -> if dotsEl.innerHTML.length > 2 then dotsEl.innerHTML = "" else dotsEl.innerHTML += "."
    interval = setInterval fn, 500
  stopLoading = () -> clearInterval(interval); dotsEl.innerHTML = ""
  startLoading()
  ###


  #displayError = (title, body) -> $('#errormsg-auth').html('===============================<br/>' + title + '<br />===============================<br/><br/>' + body)
  #connectionError = () -> displayError('ERROR: Unable to reach server.', 'Please check: <br /> 1. your internet connection <br />2. if the server is online.')
  #timeout = setTimeout connectionError, 5000

  class Authenticator
    @auth: () ->
      accessToken = window.sessionStorage.getItem('access_token')
      if accessToken
        App.initWebsocket(accessToken)
      else
        Authenticator.refresh()
        #TODO: what if accessToken is here but expired ?

    @refresh: (refreshToken) ->
      refreshToken = window.localStorage.getItem('refresh_token')
      phone = window.localStorage.getItem('phone')
      if refreshToken && phone
        $.post( {
          url: '/refresh'
          data: { refresh_token: refreshToken, phone: phone }
          success: (data) ->
            window.sessionStorage.setItem('access_token', data.access_token)
            Authenticator.auth()
          error: () ->
            window.localStorage.removeItem('refresh_token')
            Authenticator.displayForm()
        })
      else
        Authenticator.displayForm()

    @displayForm: () ->
      $('#content').html($('#auth-form').html())
      formEl = $('#content form')
      formEl.on 'submit', () ->
        phone     = formEl.find('input[name=phone]').val()
        password  = formEl.find('input[name=password]').val()
        isTrusted  = formEl.find('input[name=is_trusted]').is(':checked')
        $.post( {
          url: '/auth',
          data: { phone: phone , password: password, is_trusted: isTrusted },
          success: (data) ->
            window.sessionStorage.setItem('access_token', data.access_token)
            if data.phone && data.refresh_token
              window.localStorage.setItem('phone', data.phone)
              window.localStorage.setItem('refresh_token', data.refresh_token)
            Authenticator.auth()
          error: (e) ->
            msg = ''
            try
              errors = JSON.parse e.responseText
              msg =  _.map(errors, (error) -> return error.message).join('<br/> - ')
            catch e2
              msg = e.responseText
            $('#errormsg-auth').html('Errors:<br/>=======<br/> - ' + msg)
        })


    accessToken = window.sessionStorage.getItem('access_token')
    if accessToken
      $('#content').html($('#continue-template').html())
      btn = $('#content button')
      btn.on 'click', () ->
        Authenticator.auth()
    else
      Authenticator.refresh()
  return App
