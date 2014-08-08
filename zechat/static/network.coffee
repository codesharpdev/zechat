class zc.InFlight extends zc.Controller

  initialize: ->
    @serial = 0
    @pending = {}

  wrap: (msg) ->
    msg._serial = (@serial += 1)
    deferred = Q.defer()
    @pending[msg._serial] = deferred
    return deferred.promise

  reply: (msg) ->
    return unless msg._serial
    deferred = @pending[msg._serial]
    return unless deferred
    delete @pending[msg._serial]
    deferred.resolve(msg)


class zc.Transport extends zc.Controller

  initialize: (options) ->
    @in_flight = new zc.InFlight(app: @app)
    @model = new Backbone.Model(state: 'closed')
    @queue = []
    @app.vent.on('start', _.bind(@connect, @))
    @app.reqres.setHandler 'send-packet', _.bind(@send, @)
    @app.commands.setHandler 'reconnect', =>
      if @model.get('state') == 'closed'
        @connect()
    @app.reqres.setHandler 'transport-state', => @model

  connect: ->
    transport_url = @app.request('urls')['transport']
    @ws = new WebSocket(transport_url)
    @ws.onmessage = @on_receive.bind(@)
    @ws.onopen = @on_open.bind(@)
    @ws.onclose = @on_close.bind(@)
    @model.set(state: 'connecting')

  on_open: ->
    @model.set(state: 'open')
    current_queue = @queue
    @queue = []
    @ws_send(
      type: 'authenticate'
      identity: @app.request('identity').get('fingerprint')
    )
    current_queue.slice().forEach (msg) =>
      @send(msg)
    @app.vent.trigger('connect')

  on_close: ->
    @model.set(state: 'closed')

  on_receive: (evt) ->
    msg = JSON.parse(evt.data)
    identity = @app.request('identity')
    my_fingerprint = identity.get('fingerprint')
    if msg.type == 'message' and msg.recipient == my_fingerprint
      @app.vent.trigger('message', msg.message)

    @in_flight.reply(msg)

  ws_send: (msg) ->
    @ws.send(JSON.stringify(msg))

  send: (msg) ->
    promise = @in_flight.wrap(msg)
    if @ws.readyState == WebSocket.OPEN
      @ws_send(msg)
    else
      @queue.push(msg)
    return promise


class zc.Receiver extends zc.Controller

  initialize: ->
    @app.vent.on('message', _.bind(@on_message, @))

  on_message: (data) ->
    thread = @app.request('thread', data.sender)
    thread.message_col.add(data)
