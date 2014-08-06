zc.create_app = (options) ->
  app_deferred = Q.defer()

  channel = options.channel or 'global'
  Backbone.Wreqr.radio.channel(channel).reset()
  app = new Backbone.Marionette.Application(channelName: channel)

  app.el = options.el
  app.$el = $(app.el)

  app.reqres.setHandler 'urls', -> options.urls
  app.reqres.setHandler 'root_el', -> app.$el
  app.reqres.setHandler 'local_storage', ->
    return options.local_storage or window.localStorage

  Object.keys(zc.modules).forEach (name) ->
    app.module name, zc.modules[name]

  setup_identity = zc.setup_identity(app)
  setup_identity.done (fingerprint) ->
    app.vent.trigger('start')
    app.commands.execute('open-conversation', fingerprint)
    app_deferred.resolve(app)

  _.defer ->
    if setup_identity.isPending()
      $(options.el).text('generating identity ...')

  return app_deferred.promise
