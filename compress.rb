require 'writechain'
require 'zlib'

class Compress < WriteChain
  def write(data,sha)
    compresseddata = Zlib::Deflate.deflate(data)
    super(compresseddata,sha)
  end

  def read_sha(sha)
    compresseddata = super(sha)
    Zlib::Inflate.inflate(compresseddata)
  end
end
