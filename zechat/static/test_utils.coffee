zc.waitfor = (check, timeout=1000) ->
  t0 = _.now()
  deferred = Q.defer()

  poll = ->
    dt = _.now() - t0
    if dt > timeout
      clearInterval(interval)
      deferred.reject('timeout')
    else

    rv = check()
    if rv?
      clearInterval(interval)
      deferred.resolve(rv)

  interval = setInterval(poll, 50)

  return deferred.promise


zc.waitevent = (obj, name) ->
  deferred = Q.defer()
  obj.once('ready', -> deferred.resolve(arguments))
  return deferred.promise


zc.some = ($qs) ->
  return $qs if $qs.length > 0


class zc.MockLocalStorage

  constructor: (data) -> @_data = _.extend({}, data)

  getItem: (key) -> @_data[key]

  setItem: (key, value) -> @_data[key] = value


zc.fixtures = {

  A_KEY: 'VrIuRMeVZkmqlS9Sa9VRritZ1eVmnyJcZZFKJUkdnvk='
  A_PUBKEY: 'B8dnDDjozeRUBsMFlPiWL4HR6kLEa9WyVRga4Q/CoXY='

  B_KEY: 'NuwWzeSWynTxvBfNxi1z5UwG7AtKwwQYpW0GlDde4Fs='
  B_PUBKEY: 'YCBnGbI2GbfWjmJl22o4IH3sIACU8Sv58fcxfDQojhI='

  A_B_ENCRYPTED: 'zc+OgEhoQm3Yu8vqsFcuvzc0FJuQ2au4+wrxt8hGkss1jDAFXEMRoRU6+g=='

  SECRET_A: 'IVK8lSlJXSE8FyY1J70bI3Yt+2y39MGCYaazfltvSMY='
  PUBKEY_A: 'hz2rYWLS+YoRWT67qi4E3/A8gBrhyj7JbnqEkCcDPFw='

  SECRET_B: 'RyHxg2NfwAjreuV6KLz4K2hQAY21flFNEScRobnaFaQ='
  PUBKEY_B: 'G9YiDu/vITvomNltZmG9ooZIU2kONviSmwljThqR2Hc='

}
