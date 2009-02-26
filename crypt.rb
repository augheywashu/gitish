require 'openssl'
require 'digest/sha1'
require 'writechain'

class BlobCrypt < WriteChain
  def initialize(child, options)
    super

    raise "You must set the :crypt_key option" unless options.has_key?('crypt_key')
    @key = Digest::SHA1.hexdigest(options['crypt_key'])
  end

  def read_sha(sha)
    data = super
    c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    c.decrypt
    c.key = @key
    #c.iv = @key
    d = c.update(data)
    d << c.final
    d
  end

  def write(data,sha)
    c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    c.encrypt
    c.key = @key
    #c.iv = @key
    e = c.update(data)
    e << c.final

    super(e,sha)
  end
end
