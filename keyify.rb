require 'digest/sha1'
require 'writechain'

class Keyify < WriteChain
  def write(data)
    sha = Digest::SHA1.hexdigest(data)
    @child.write(data,sha)
  end
end
