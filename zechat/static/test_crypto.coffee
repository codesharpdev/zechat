describe 'crypto', ->

  priv_pem = "-----BEGIN RSA PRIVATE KEY-----\nMIIEogIBAAKCAQEA4qiw8PWs7PpnnC2BUEoDRcwXF8pq8XT1/3Hc3cuUJwX/otNe\nfr/Bomr3dtM0ERLN3DrepCXvuzEU5FcJVDUB3sI+pFtjjLBXD/zJmuL3Afg91J9p\n79+Dm+43cR6wuKywVJx5DJIdswF6oQDDzhwu89d2V5x02aXB9LqdXkPwiO0eR5s/\nxHXgASl+hqDdVL9hLod3iGa9nV7cElCbcl8UVXNPJnQAfaiKazF+hCdl/syrIh0K\nCZ5opggsTJibo8qFXBmG4PkT5YbhHE11wYKILwZFSvZ9iddRPQK3CtgFiBnXbVwU\n5t67tn9pMizHgypgsfBoeoyBrpTuc4egSCpjsQIDAQABAoIBAF2sU/wxvHbwAhQE\npnXVMMcO0thtOodxzBz3JM2xThhWnVDgxCPkAhWq2X0NSm5n9BY5ajwyxYH6heTc\np6lagtxaMONiNaE2W7TqxzMw696vhnYyL+kH2e9+owEoKucXz4QYatqsJIQPb2vM\n0h+DfFAgUvNgYNZ2b9NBsLn9oBImDfYueHyqpRGTdX5urEVtmQz029zaC+jFc7BK\nY6qBRSTwFwnVgE+Td8UgdrO3JQ/0Iwk/lkphnhls/BYvdNC5O8oEppozNVmMV8jm\n61K+agOh1KD8ky60iQFjo3VdFpUjI+W0+sYiYpDb4+Z9OLOTK/5J2EBAGim9siyd\ngHspx+UCgYEA9+t5Rs95hG9Q+6mXn95hYduPoxdFCIFhbGl6GBIGLyHUdD8vmgwP\ndHo7Y0hnK0NyXfue0iFBYD94/fuUe7GvcXib93heJlvPx9ykEZoq9DZnhPFBlgIE\nSGeD8hClazcr9O99Fmg3e7NyTuVou+CIublWWlFyN36iamP3a08pChsCgYEA6gvT\npi/ZkYI1JZqxXsTwzAsR1VBwYslZoicwGNjRzhvuqmqwNvK17dnSQfIrsC2VnG2E\nUbE5EIAWbibdoL4hWUpPx5Tl096OjC3qBR6okAxbVtVEY7Rmv7J9RwriXhtD1DYp\neBvo3eQonApFkfI8Lr2kuKGIgwzkZ72QLXsKJiMCgYBZXBCci0/bglwIObqjLv6e\nzQra2BpT1H6PGv2dC3IbLvBq7hN0TQCNFTmusXwuReNFKNq4FrB/xqEPusxsQUFh\nfv2Il2QoI1OjUE364jy1RZ7Odj8TmKp+hoEykPluybYYVPIbT3kgJy/+bAXyIh5m\nAv2zFEQ86HIWMu4NSb0bHQKBgETEZNOXi52tXGBIK4Vk6DuLpRnAIMVl0+hJC2DB\nlCOzIVUBM/VxKvNP5O9rcFq7ihIEO7SlFdc7S1viH4xzUOkjZH2Hyl+OLOQTOYd3\nkp+AgfXpg8an4ujAUP7mu8xaxns7zsNzr+BCgYwXmIlhWz2Aiz2UeL/IsfOpRwuV\n801xAoGADQB84MJe/X8xSUZQzpn2KP/yZ7C517qDJjComGe3mjVxTIT5XAaa1tLy\nT4mvpSeYDJkBD8Hxr3fB1YNDWNbgwrNPGZnUTBNhxIsNLPnV8WySiW57LqVXlggH\nvjFmyDdU5Hh6ma4q+BeAqbXZSJz0cfkBcBLCSe2gIJ/QJ3YJVQI=\n-----END RSA PRIVATE KEY-----"

  pub_pem = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4qiw8PWs7PpnnC2BUEoD\nRcwXF8pq8XT1/3Hc3cuUJwX/otNefr/Bomr3dtM0ERLN3DrepCXvuzEU5FcJVDUB\n3sI+pFtjjLBXD/zJmuL3Afg91J9p79+Dm+43cR6wuKywVJx5DJIdswF6oQDDzhwu\n89d2V5x02aXB9LqdXkPwiO0eR5s/xHXgASl+hqDdVL9hLod3iGa9nV7cElCbcl8U\nVXNPJnQAfaiKazF+hCdl/syrIh0KCZ5opggsTJibo8qFXBmG4PkT5YbhHE11wYKI\nLwZFSvZ9iddRPQK3CtgFiBnXbVwU5t67tn9pMizHgypgsfBoeoyBrpTuc4egSCpj\nsQIDAQAB\n-----END PUBLIC KEY-----"

  it 'should sign and verify signature', (done) ->

    data = 'foo'

    Crypt.make priv_pem, (err, signer) ->
        signer.sign data, (err, signed) ->
            Crypt.make pub_pem, (err, verifier) ->
                verifier.verify signed, (err, verified) ->
                    expect(verified).toEqual(data)
                    done()

  it 'should encrypt and decrypt', (done) ->

    data = 'foo'

    Crypt.make pub_pem, (err, encrypter) ->
        encrypter.encrypt data, (err, encrypted) ->
            Crypt.make priv_pem, (err, decrypter) ->
                decrypter.decrypt encrypted, (err, decrypted) ->
                    expect(decrypted).toEqual(data)
                    done()
