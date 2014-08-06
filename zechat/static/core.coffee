zc = window.zc = {}

zc.modules = {}


zc.utcnow_iso = ->
  (new Date()).toJSON()


zc.serialize_form = (el) ->
  pairs = $(el).serializeArray()
  return _.object(_.pluck(pairs, 'name'), _.pluck(pairs, 'value'))


zc.post_json = (url, data, callback) ->
  $.ajax(
    type: "POST"
    url: url
    data: JSON.stringify(data)
    contentType: "application/json"
    dataType: "json"
    success: callback
  )


Handlebars.registerHelper 'format_time', (iso_time) ->
  time = d3.time.format.iso.parse(iso_time)
  return d3.time.format('%b-%-d %H:%M')(time)


Backbone.Marionette.TemplateCache.prototype.compileTemplate = (src) ->
  Handlebars.compile(src)


class zc.BlankView extends Backbone.Marionette.ItemView

  template: -> ''


class zc.AppLayout extends Backbone.Marionette.LayoutView

  template: '#app-layout-html'

  regions:
    header: '.app-header'
    contacts: '.app-contacts'
    main: '.app-main'


class zc.HeaderView extends Backbone.Marionette.ItemView

  className: 'header-container tall'
  template: '#header-html'

  events:
    'click .header-btn-myid': (evt) ->
      evt.preventDefault()
      @trigger('click-myid')

    'click .header-btn-add-contact': (evt) ->
      evt.preventDefault()
      @trigger('click-add-contact')


class zc.Header extends Backbone.Marionette.Controller

  createView: ->
    view = new zc.HeaderView()

    view.on 'click-myid', =>
      myid = new zc.Identity(app: @options.app)
      @options.app.commands.execute('show-main', myid.createView())

    view.on 'click-add-contact', =>
      add_contact = new zc.AddContact(app: @options.app)
      @options.app.commands.execute('show-main', add_contact.createView())

    return view


class zc.AddContactView extends Backbone.Marionette.ItemView

  tagName: 'form'
  template: '#add-contact-html'

  ui:
    url: '[name=url]'

  events:
    'submit': (evt) ->
      evt.preventDefault()
      url = @ui.url.val()
      if url
        this.trigger('add', url)

  onShow: ->
    @ui.url.focus()


class zc.AddContact extends Backbone.Marionette.Controller

  createView: ->
    view = new zc.AddContactView()

    view.on 'add', (url) =>
      Q($.get(url)).done (resp) =>
        @options.app.commands.execute('open-conversation', resp.fingerprint)

    return view


class zc.Transport extends Backbone.Marionette.Controller

  initialize: (options) ->
    @queue = []
    @options.app.vent.on('start', _.bind(@connect, @))
    @options.app.commands.setHandler 'send-packet', _.bind(@send, @)

  connect: ->
    transport_url = @options.app.request('urls')['transport']
    @ws = new WebSocket(transport_url)
    @ws.onmessage = _.bind(@on_receive, @)
    @ws.onopen = _.bind(@on_open, @)
    @send(
      type: 'authenticate'
      identity: @options.app.request('identity').get('fingerprint')
    )

  on_open: ->
    current_queue = @queue
    @queue = []
    current_queue.forEach (msg) =>
      @send(msg)

  on_receive: (evt) ->
    msg = JSON.parse(evt.data)
    identity = @options.app.request('identity')
    my_fingerprint = identity.get('fingerprint')
    if msg.type == 'message' and msg.recipient == my_fingerprint
      @options.app.vent.trigger('message', msg.message)

  send: (msg) ->
    if @ws.readyState == WebSocket.OPEN
      @ws.send(JSON.stringify(msg))
    else
      @queue.push(msg)


class zc.Persist extends Backbone.Marionette.Controller

  initialize: ->
    @key = @options.key
    @model = @options.model
    value = @options.app.request('local_storage').getItem(@key)
    if value
      @model.set(JSON.parse(value))
    @model.on('change', _.bind(@save, @))

  save: ->
    @options.app.request('local_storage').setItem(@key, JSON.stringify(@model))


class zc.Receiver extends Backbone.Marionette.Controller

  initialize: ->
    @options.app.vent.on('message', _.bind(@on_message, @))

  on_message: (data) ->
    message_col = @options.app.request('message_collection', data.sender)
    message_col.add(data)


class zc.MessageManager extends Backbone.Marionette.Controller

  initialize: ->
    @collection_map = {}
    @options.app.reqres.setHandler('message_collection',
      _.bind(@get_message_collection, @))

  get_message_collection: (peer) ->
    unless @collection_map[peer]
      @collection_map[peer] = new Backbone.Collection

    return @collection_map[peer]


zc.modules.core = ->
  @models =
    identity: new Backbone.Model
      fingerprint: 'foo'

  @message_manager = new zc.MessageManager(app: @app)

  @persist_identity = new zc.Persist
    app: @app
    key: 'identity'
    model: @models.identity

  zc.set_identity = (fingerprint) =>
    @models.identity.set('fingerprint', fingerprint)

  @app.reqres.setHandler 'identity', => @models.identity

  @transport = new zc.Transport(app: @app)
  @receiver = new zc.Receiver(app: @app)

  @app.commands.setHandler 'show-main', (view) =>
    @layout.main.show(view)

  @app.vent.on 'start', =>
    @layout = new zc.AppLayout(el: @app.request('root_el'))
    @layout.render()

    @header = new zc.Header(app: @app)
    @layout.header.show(@header.createView())
