define (require) ->
  Backbone = require 'backbone'
  Marionette = require 'backbone.marionette'
  Val = require 'helpers/validate'

  class ContactModel extends Backbone.Model
    #idAttribute : 'phone'

    @schema:
      # TODO: this phone number regex below accept spaces, check if it's a problem later.
      id: Val.String().required().regex(/^\+(?:[0-9] ?){6,14}[0-9]$/) #phone number
      name: Val.String().required().regex(/^[a-zA-Z0-9_]*$/).max(100)
      note: Val.String().max(1000)

    validate: (attrs, options) ->
      attrs = attrs || @attributes
      return Val.many(attrs, ContactModel.schema)

  class ContactForm extends Marionette.ItemView
    template: '#contact-form'
    id: 'contact-form'
    #regions:
    #  name:  'input[name=name]'
    #  phone: 'input[name=phone]'
    #  note:  'input[name=note]'


  class ContactView extends Marionette.ItemView
    template: '#contact-template'
    modelEvents:
      change: 'render'
    tagName: 'li'
    className: 'pure-menu-item'

    serializeData: () ->
      data = super()
      data = _.extend data, {
        id: data.id,
        name: data.name || "Unknown pohny"
      }
      return data

  class ContactCollectionView extends Marionette.CollectionView
    childView: ContactView
    tagName: 'ul'
    className: 'pure-menu-list'
    #id: 'contact-list'
    filterExp: ""

    searchFilter: (models1) ->
      name = null
      phone = null
      filterExp = @filterExp.toLowerCase().trim()
      regExp = new RegExp('(' + @filterExp.trim() + ')', 'i')
      models2 = {}
      for index, model1 of models1
        name = (model1.get('name') || "").toLowerCase().trim()
        phone = model1.id.trim()
        if name.indexOf(filterExp) > -1 || phone.indexOf(filterExp) > -1
          model2 = model1
          if filterExp.length > 0
            model2 = new ContactModel({
              name: (model1.get('name') || "").replace(regExp, '<p class="highlight">$1</p>')
              id: model1.id.replace(regExp, '<p class="highlight">$1</p>')
            })
          models2[index] = model2
      return models2

    showCollection: () ->
      models = @searchFilter(@collection.models)
      for index, model of models
        @addChild(model, @childView, index)

  class ContactLayout extends Marionette.LayoutView
    #template: _.template('<h1>Contacts</h1><div id="contact-list"></div>')
    template: '#contact-layout'

    regions:
      list: '#contact-list'

    #childEvents:
    #  render: () ->
    #    console.log('A child view has been rendered.')

  class ContactManager
    constructor: (@app, @dataSource) ->
      @contacts = @dataSource.conversations

    renderContactList: () ->
      #ContactCollectionView.prototype.childView = ContactView
      @view = new ContactCollectionView({ collection: @contacts })
      #contactCount = 0
      #for index, model of @contacts.models then if model.get('name') then contactCount++
      #if contactCount < 1
      if @contacts.models.length < 1
        @renderContactForm()
        $('#contact-notifier').html('<br/>No contact registered, please add a contact:<br/>')
      else @layout.$el.find('#menu2').show()
      @layout.getRegion('list').show(@view, {})

    renderContactForm: () ->
      @view = new ContactForm()
      @layout.getRegion('list').show(@view, {})
      @layout.$el.find('#menu2').hide()

    getContactFilter: (ctx) ->
      return (e) ->
        $('#search-clear').show()
        if ctx.view instanceof ContactCollectionView == false || ctx.view.children && ctx.view.children.length == 0
          ctx.renderContactList()
        ctx.view.filterExp = e.target.value
        ctx.view.render()
        if ctx.view.children && ctx.view.children.length == 0
          ctx.renderContactForm()

    getClearSearch: (ctx) ->
      return (e) ->
        $(e.target).hide()
        $('#search').val("")
        #e.target.parentElement.getElementById('search')[0].value = ""
        ctx.renderContactList()
        $('#search').focus()


    getAddContact: (ctx) ->
      return (e) ->
        ctx.renderContactForm()
        ctx.view.$el.find('input[name=phone]').attr("disabled", false)

    getDisplayConversation: (ctx) ->
      return (e) ->
        phone = $(e.currentTarget).find('.contact-phone').html()
        ctx.app.router.navigate("conversation/" + phone , true)

    getSaveContact: (ctx) ->
      return (e) ->
        contact = new ContactModel({
          name:  $(e.target).find('input[name=name]').val()
          id: $(e.target).find('input[name=phone]').val()
          note: $(e.target).find('textarea[name=note]').val()
        })
        errors = contact.validate()

        # clean previous errors
        for key of contact.attributes
          ctx.view.$('#errormsg-' + key).html('')
          $(e.target).find('input[name=' + key + ']').removeClass('form-error')

        if errors && errors.length > 0
          for err in errors
            msg = 'Value ' + JSON.stringify(err[0]) + " is " + err[1]
            ctx.view.$('#errormsg-' + err[0]).html(msg)
            #ctx.view[err[0]].addClass('form-error')
            $(e.target).find('input[name=' + err[0] + ']').addClass('form-error')
        else
          ctx.contacts.add(contact, {merge: true})
          Backbone.history.fragment = null
          ctx.app.router.navigate("contacts", true)

    getBackToList: (ctx) ->
      return (e) -> ctx.renderContactList()

    getEditContact: (ctx) ->
      return (e) ->
        $(e.target).removeClass('dragging')
        e.preventDefault()

        ctx.renderContactForm()
        contact = ctx.contacts.get e.originalEvent.dataTransfer.getData("text")
        ctx.view.$el.find('input[name=name]').val(contact.get("name"))
        ctx.view.$el.find('input[name=phone]').val(contact.id).attr("disabled", true)
        ctx.view.$el.find('textarea[name=note]').val(contact.get("note"))

    getCallContact: (ctx) ->
      return (e) ->
        $(e.target).removeClass('dragging')
        e.preventDefault()
        ctx.app.call e.originalEvent.dataTransfer.getData("text")

    getTrashContact:(ctx) ->
      return (e) ->
        $(e.target).removeClass('dragging')
        e.preventDefault()
        ctx.contacts.remove e.originalEvent.dataTransfer.getData("text")

        contactCount = 0
        for index, model of ctx.contacts.models then if model.get('name') then contactCount++
        #if @contacts.models.length < 1 then @renderContactForm()
        if contactCount < 1
          ctx.renderContactForm()
          $('#contact-notifier').html('<br/>No contact registered, please add a contact:<br/>')

    getDisplayContactList: (ctx) ->
      return (e) -> ctx.app.router.navigate("contacts", true)

    render: (@conversation = false) ->

      @contacts.comparator = 'name'
      @contacts.sort()
      @layout = new ContactLayout( {
        events:
          'keyup #search': @getContactFilter(@)
          'click #search-clear': @getClearSearch(@)
          'click #add-contact': @getAddContact(@)
          #'click .contact': @getEditContact(@)
          'click .contact': @getDisplayConversation(@)
          'submit form': @getSaveContact(@)
          'click .back': @getBackToList(@)
          'dragover .drag': (e) -> e.preventDefault()
          'dragenter .drag': (e) -> e.preventDefault(); e.stopPropagation(); $(e.target).addClass('dragging')
          'dragleave .drag': (e) -> e.preventDefault(); e.stopPropagation(); $(e.target).removeClass('dragging')
          'drop .trash': @getTrashContact(@)
          'drop .edit': @getEditContact(@)
          'drop .call': @getCallContact(@)
          'focus #search': @getDisplayContactList(@)
          'dragstart .contact': (e) ->
            e.originalEvent.dataTransfer.setData("text", $(e.currentTarget).find('.contact-phone').html())
      })
      @layout.render()
      renderMethod = if @conversation then 'renderContactForm' else 'renderContactList'
      @app.show(@layout, () => @[renderMethod]() )
      if @conversation
        $('input[name=name]').focus()
        if @conversation.get
          @view.$el.find('input[name=name]').val(@conversation.get("name"))
          @view.$el.find('input[name=phone]').val(@conversation.id).attr("disabled", true)
          @view.$el.find('textarea[name=note]').val(@conversation.get("note"))
      else $('#search').focus()
      #$('.edit').show()

  exports = {}
  exports.Manager = ContactManager
  #exports.Collection = ContactCollection
  return exports
