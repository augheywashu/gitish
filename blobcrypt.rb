require 'openssl'
require 'digest/sha1'

class BlobCrypt
  def initialize(store)
    raise "You must set the ENV variable CRYPT_KEY" unless ENV['CRYPT_KEY']
    @key = Digest::SHA1.hexdigest(ENV['CRYPT_KEY'])
    @store = store
  end

  def method_missing(method, *args)
    @store.send(method,*args)
  end

  def read_sha(sha)
    data = @store.read_sha(sha)
    c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    c.decrypt
    c.key = @key
    #c.iv = @key
    d = c.update(data)
    d << c.final
    d
  end


  def write(data,sha = nil)
    c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    c.encrypt
    c.key = @key
    #c.iv = @key
    e = c.update(data)
    e << c.final

    @store.write(e,sha)
  end
end
