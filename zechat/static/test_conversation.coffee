describe 'conversation', ->

  FIX = zc.fixtures

  it 'should send a message and receive it back', (done) ->
    identity_json = JSON.stringify(key: FIX.PRIVATE_KEY)

    $app = $('<div>')
    app = zc.create_app(
      urls: zc.TESTING_URL_MAP
      el: $app[0]
      local_storage: new zc.MockLocalStorage(identity: identity_json)
    )

    zc.waitfor(-> zc.some($app.find('.conversation-compose')))
    .then ->
      $form = $app.find('.conversation-compose form')
      $form.find('[name=message]').val('hello world')
      $form.submit()

      get_messages = ->
        $history = $app.find('.conversation-history')
        messages = $history.find('.message-text').text()
        return messages if messages.length > 0

      return zc.waitfor(get_messages, 3000)
    .then (messages) ->
      expect(messages).toEqual("hello world")
    .catch (err) ->
      if err == 'timeout'
        expect('timed out').toBe(false)
        return
      throw(err)
    .finally ->
      zc.remove_handlers(app)
      done()