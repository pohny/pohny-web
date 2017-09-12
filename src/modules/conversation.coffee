define (require) ->
  Backbone = require 'backbone'
  Marionette = require 'backbone.marionette'
  Val = require 'helpers/validate'
  DateHelper = require 'helpers/date-helper'
  _ = require 'underscore'
  exports = {}

  class ConversationModel extends Backbone.Model
    #idAttribute : 'phone'

  class ConversationView extends Marionette.ItemView
    template: '#conversation-template'
    modelEvents:
      change: 'render'
    tagName: 'li'
    className: 'pure-menu-item'

    serializeData: () ->
      data = super()
      data = _.extend data, {
        id: data.id,
        name: data.name || data.id,
        last_msg: data.messages.at(0).get('body'),
        at: data.messages.at(0).get('at'),
        unread: data.unread
      }
      if data.messages.at(0).get('me') == true then data.last_msg = 'Me:' + data.last_msg
      if data.last_msg.length > 20 then data.last_msg = data.last_msg.slice(0, 24) + '...'
      data.unreadLabel = if data.unread > 0 then '-(<p style="color:red;display:inline;">' + data.unread + '</p>)-' else ''
      data.date = DateHelper.autoFormatDate(new Date(data.at * 1000))
      return data

  class ConversationCollection extends Backbone.Collection
    model: ConversationModel
    #comparator: "at"

  class ConversationCollectionView extends Marionette.CollectionView
    childView: ConversationView
    tagName: 'ul'
    className: 'pure-menu-list'
    id: 'contact-list'
    showCollection: () ->
      for index, model of @collection.models
        if model.get('messages') && model.get('messages').models.length > 0
          @addChild(model, @childView, index)

  class ConversationLayout extends Marionette.LayoutView
    template: '#contact-layout'

    regions:
      list: '#contact-list'

  class ConversationManager
    constructor: (@app, @dataSource) ->
      @conversations = @dataSource.conversations

    renderConversationList: () ->
      @view = new ConversationCollectionView({ collection: @conversations })
      @layout.getRegion('list').show(@view, {})
      fnName = if @layout.list.currentView && @layout.list.currentView.children.length > 0 then 'show' else 'hide'
      @layout.$el.find('#menu2')[fnName]()

      @layout.$el.find('.call, .edit').hide()

    refresh: () ->
      @renderConversationList()

    getDisplayContactList: (ctx) ->
      return (e) -> ctx.app.router.navigate("contacts", true)

    getDisplayConversation: (ctx) ->
      return (e) ->
        phone = ctx.layout.$el.find(e.currentTarget).find('.contact-phone').html()
        ctx.app.router.navigate("conversation/" + phone , true)


    getTrashConversation:(ctx) ->
      return (e) ->
        $(e.target).removeClass('dragging')
        e.preventDefault()
        conversation = ctx.conversations.get e.originalEvent.dataTransfer.getData("text")
        ctx.layout.list.currentView._onCollectionRemove(conversation)
        conversation.get('messages').reset()
        fnName = if ctx.layout.list.currentView.children.length > 0 then 'show' else 'hide'
        #@layout.$el.find('#menu2')[fnName]()
        $('#menu2')[fnName]()

    render: () ->
      @conversations.comparator = (model) ->
        return if model.get('messages') && model.get('messages').models.length > 0 then - model.get('messages').at(0).get('at') else 0
      @conversations.sort()
      @layout = new ConversationLayout( {
        events:
          'focus #search': @getDisplayContactList(@)
          'click .conversation': @getDisplayConversation(@)
          'drop .trash': @getTrashConversation(@)
          'dragover .trash': (e) -> e.preventDefault()
          'dragenter .trash': (e) -> e.preventDefault(); e.stopPropagation(); $(e.target).addClass('dragging')
          'dragleave .trash': (e) -> e.preventDefault(); e.stopPropagation(); $(e.target).removeClass('dragging')
          'dragstart .conversation': (e) ->
            e.originalEvent.dataTransfer.setData("text", $(e.currentTarget).find('.contact-phone').html())
      })
      @layout.render()
      @app.show(@layout, () => @renderConversationList())

  exports = {}
  exports.Manager = ConversationManager
  exports.Collection = ConversationCollection
  return exports
