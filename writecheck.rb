require 'writechain'

class WriteCheck < WriteChain
  def initialize(child,options = { })
    super
    @datasize = 0
    @numwrites = 0
    @numpassed = 0
    @sizepassed = 0
  end

  def stats
    ["WriteCheck: asked to write #{@numwrites.commaize} blocks",
      "WriteCheck: asked to write #{@datasize.commaize} bytes",
      "WriteCheck: passed on #{@numpassed.commaize} blocks",
      "WriteCheck: passed on #{@sizepassed.commaize} bytes"] + super
  end

  def write(data,sha)
    @numwrites += 1
    @datasize += data.size
    if @child.has_sha?(sha,false)
      return sha
    else
      @numpassed += 1
      @sizepassed += data.size
      return @child.write(data,sha)
    end
  end
end
