require 'zlib'

class DataStore
  def initialize(file)
    @file = File.open(file,"ab+")
    @file.seek(0,IO::SEEK_END)
  end

  def close
    @file.close
  end

  def size
    @file.tell
  end

  def read(key)
    offset,size = key.split(',')
    offset = offset.to_i
    size = size.to_i
    @file.seek(offset)
    data = @file.read(size)
    Zlib::Inflate.inflate(data)
  end

  def write(data)
    return "0,0" if data.size == 0
    @file.seek(0,IO::SEEK_END)
    out = Zlib::Deflate.deflate(data)
    offset = @file.tell
    @file.write out
    @file.fsync
    "#{offset},#{out.size}"
  end
end

