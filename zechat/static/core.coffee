class zc.Controller extends Backbone.Marionette.Controller

  constructor: (options) ->
    @app = options.app
    super(options)


class zc.BlankView extends Backbone.Marionette.ItemView

  template: -> ''


class zc.AppLayout extends Backbone.Marionette.LayoutView

  template: 'app_layout.html'

  regions:
    header: '.app-header'
    peerlist: '.app-peerlist'
    main: '.app-main'


class zc.HeaderView extends Backbone.Marionette.ItemView

  className: 'header-container tall'
  template: 'header.html'

  initialize: ->
    @model.on('change', => @render())

  serializeData: ->
    state = @model.get('state')
    if state == 'closed'
      return cls: 'btn-danger header-btn-connect', text: "✘"
    if state == 'connecting'
      return cls: 'btn-warning', disabled: true, text: "…"
    if state == 'open'
      return cls: 'btn-success', disabled: true, text: "✔"

  events:
    'click .header-btn-myid': (evt) ->
      evt.preventDefault()
      @trigger('click-myid')

    'click .header-btn-add-contact': (evt) ->
      evt.preventDefault()
      @trigger('click-add-contact')

    'click .header-btn-connect': (evt) ->
      evt.preventDefault()
      @trigger('click-connect')


class zc.Header extends zc.Controller

  createView: ->
    view = new zc.HeaderView(model: @app.request('transport-state'))

    view.on 'click-myid', =>
      myid = @app.request('identity-controller')
      @app.commands.execute('show-main', myid.createView())

    view.on 'click-add-contact', =>
      add_contact = new zc.AddContact(app: @app)
      @app.commands.execute('show-main', add_contact.createView())

    view.on 'click-connect', =>
      @app.commands.execute('reconnect')

    return view


class zc.AddContactView extends Backbone.Marionette.ItemView

  tagName: 'form'
  template: 'add_contact.html'

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


class zc.AddContact extends zc.Controller

  createView: ->
    view = new zc.AddContactView()

    view.on 'add', (url) =>
      Q($.get(url)).done (resp) =>
        @app.commands.execute('open-thread', resp.fingerprint)

    return view


class zc.Persist extends zc.Controller

  initialize: ->
    @key = @options.key
    @model = @options.model
    value = @app.request('local_storage').getItem(@key)
    if value
      @model.set(JSON.parse(value))
    @model.on('change', @save)

  save: =>
    @app.request('local_storage').setItem(@key, JSON.stringify(@model))


class zc.Client extends zc.Controller

  initialize: ->
    @identity = @options.identity
    @transport = @options.transport
    @transport.on('open', @on_open)
    @transport.on('packet', @on_packet)

  on_open: (open) =>
    @identity.authenticate(@transport)

    .then =>
      @transport.send(type: 'list', identity: @identity.fingerprint())

    .then (resp) =>
      @transport.send(
        type: 'get'
        identity: @identity.fingerprint()
        messages: resp.messages
      )

    .done (resp) =>
      for msg in resp.messages
        @on_message(msg.message)

      @trigger('ready')

  on_packet: (packet) =>
    if packet.type == 'message'
      if packet.recipient == @identity.fingerprint()
        @on_message(packet.message)

  on_message: (data) ->
    message = JSON.parse(zc.b64decode(data))
    peer = @app.request('peer', message.sender)
    peer.message_col.add(message)

  send: (recipient, message) ->
    @transport.send(
      type: 'message'
      recipient: recipient
      message: zc.b64encode(JSON.stringify(message))
    )


zc.modules.core = ->
  @models =
    identity: new Backbone.Model
    peer_col: new Backbone.Collection

  @persist_identity = new zc.Persist
    app: @app
    key: 'identity'
    model: @models.identity

  zc.set_identity = (fingerprint) =>
    @models.identity.set('fingerprint', fingerprint)

  @app.reqres.setHandler 'identity', => @models.identity

  @transport = new zc.Transport(app: @app)
  @peerlist = new zc.PeerList(app: @app, peer_col: @models.peer_col)
  @identity = new zc.Identity(app: @app)
  @client = new zc.Client(
    app: @app
    transport: @transport
    identity: @identity
  )

  @app.reqres.setHandler 'identity-controller', => @identity
  @app.reqres.setHandler 'client', => @client

  @app.commands.setHandler 'show-main', (view) =>
    @layout.main.show(view)

  @app.vent.on 'start', =>
    @layout = new zc.AppLayout(el: @app.request('root_el'))
    @layout.render()

    @header = new zc.Header(app: @app)
    @layout.header.show(@header.createView())
    @layout.peerlist.show(@peerlist.createView())
