require 'zlib'

class DataStore
  attr_reader :compress

  def initialize(file)
    @file = File.open(file,"ab+")
    @file.seek(0,IO::SEEK_END)
    @compress = true
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
    if compress
      Zlib::Inflate.inflate(data)
    else
      data
    end
  end

  def write(data)
    return "0,0" if data.size == 0

    data = Zlib::Deflate.deflate(data) if compress

    @file.flock File::LOCK_EX

      @file.seek(0,IO::SEEK_END)
      offset = @file.tell
      @file.write data
      @file.fsync

    @file.flock File::LOCK_UN
    "#{offset},#{data.size}"
  end
end

