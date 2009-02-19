require 'writechain'

class WriteCheck < WriteChain
  def write(data,sha)
    if @child.has_sha?(sha)
      return sha
    else
      return @child.write(data,sha)
    end
  end
end
