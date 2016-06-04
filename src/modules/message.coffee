define (require) ->
  Backbone = require 'backbone'
  Marionette = require 'backbone.marionette'
  Val = require 'helpers/validate'
  DateHelper = require 'helpers/date-helper'

  class MessageModel extends Backbone.Model
    #idAttribute : ''

    @schema:
      body: Val.String().required().min(0)
      #at: Val.Number().required()
      #me: Val.Boolean

    validate: (attrs, options) ->
      attrs = attrs || @attributes
      return Val.many(attrs, MessageModel.schema)

  class MessageForm extends Marionette.ItemView
    template: '#message-form'


  class MessageView extends Marionette.ItemView
    template: '#message-template'
    modelEvents:
      change: 'render'
    tagName: 'div'
    className: 'message'

    serializeData: () ->
      data = super()
      data.position = if data.me then "right" else "left"
      data.details = DateHelper.autoFormatDateTime(new Date(data.at * 1000))
      return data



  class MessageCollection extends Backbone.Collection
    model: MessageModel
    #comparator: (model) -> return - model.get("at")
    #comparator: 'at'

    preinitialize: (models, options) ->
      @id = options.id

    bindEvents: (app) ->
      @on 'reset', (collection) ->
        app.sendMessage('messages.reset', [collection.id])
      @on 'add', (model, collection) ->
        if model.get('me') then app.sendMessage('messages.add', [collection.id, model.toJSON()])


  class MessageCollectionView extends Marionette.CollectionView
    childView: MessageView
    tagName: 'div'
    id: 'message-container'
    #id: 'message-list'

    #emptyView: do() -> Marionette.ItemView.extend({template: conversationEmptyTemplate})
    showCollection: () ->
      model = null
      for index in [@collection.models.length...0]
      #for index in [0..@collection.models.length]
      #for index, model of @collection.models
        model = @collection.at(index - 1)
        #model = @collection.at(index)
        #console.log @collection.models.length - index
        #console.log DateHelper.formatDateTime(new Date(model.get('at') * 1000))
        @addChild(model, @childView, @collection.models.length - index)

  class MessageLayout extends Marionette.LayoutView
    template: '#message-layout'

    regions:
      list: '#message-list'

    #TODO: I should probably delegate work below to a dedicated ItemView
    serializeData: () ->
      data = super()
      data.name = @options.name
      data.phone = @options.phone
      return data

    #childEvents:
    #  render: () ->
    #    console.log('A child view has been rendered.')

  class MessageManager
    constructor: (@app, @dataSource) ->


    renderMessageList: () ->
      @view = new MessageCollectionView({ collection: @messages })
      ctx = @
      @view.on "render", (view) ->
        el = @$el.parent()
        el.scrollTop(el.prop("scrollHeight"))

        #mark as read
        if ctx.conversation && ctx.conversation.get('unread') > 0
          ctx.app.sendMessage('conversations.read', [ctx.conversation.get('phone')])
          ctx.conversation.set('unread', 0, {silent: true})
        ctx.app.incrConversation()

      @layout.getRegion('list').show(@view, {})

    refresh: () ->
      @renderMessageList()

    getBackToList: (ctx) ->
      return (e) -> ctx.app.router.navigate("conversations", true)

    getSaveMessage: (ctx) ->
      return (e) ->
        el = $('#message-footer textarea')
        el.focus()
        body = el.val()
        message = new MessageModel( {
          body: body
          at: DateHelper.getTimestampInSec()
          me: true
        })
        errors = message.validate()

        if errors && errors.length > 0
          trace errors
        else
          ctx.messages.add message
          el.val("")

    renderMessageForm: () ->
      @view = new MessageForm()
      @layout.getRegion('content').show(@view, {})

    getCallContact: (ctx) ->
      return (e) ->
        ctx.app.call ctx.messages.id

    render: (@conversation) ->

      @messages = @conversation.get('messages')
      if !@messages
        @messages = new MessageCollection([], {id: @conversation.get('phone') })
        @messages.bindEvents(@app)
        @conversation.set('messages', @messages)
      @messages.comparator = (model) -> return - model.get 'at'
      @messages.sort()
      @layout = new MessageLayout( {
        events:
          'click .back': @getBackToList(@)
          'click .call': @getCallContact(@)
          #'click .send': @getSaveMessage(@)
          'submit form': @getSaveMessage(@)
        name: @conversation.get('name') || 'NoName'
        phone: @conversation.get('phone')
      })
      @layout.render()
      @app.show(@layout, () => @renderMessageList() )
      el = $("#message-list")
      el.scrollTop(el.prop("scrollHeight"))
      $('#message-footer textarea').focus()
      #@layout.getRegion('content').show(new MessageView( model: @messages.models[0]), {})
      #@layout.getRegion('content').show(new MessageForm(), {})
      #@layout.getRegion('content').show(new MessageCollectionView({ collection: @messages }), {})

  exports = {}
  exports.Manager = MessageManager
  exports.Collection = MessageCollection
  return exports
