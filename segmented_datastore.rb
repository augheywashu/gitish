class SegmentedDataStore
  # Make the maximum size of a single store 4GB (1B = 1000 bytes)
  MAXSIZE = 4000000000
  def initialize(filebase,storeclass)
    @filebase = filebase
    @storeclass = storeclass
    @openindex = -1
  end

  def close
    @store.close if @store
    @store = nil
  end

  def write(data)
    if @store.nil? or @store.size > MAXSIZE
      open_last_index(@openindex + 1)
    end
    key = @store.write(data)
    # Prepend the index number to the key
    "#{@openindex}-#{key}"
  end

  def read(key)
    key=~/^(\d+)-(.*)/
    index = $1.to_i
    open_store(index)
    @store.read($2)
  end

  def method_missing(method, *args)
    @store.send(method,*args)
  end

  protected

  def open_store(index)
    return if @openindex == index
    self.close
    filename = sprintf("#{@filebase}-%03d",index)
    @openindex = index
    @store = @storeclass.new(filename)
  end

  def open_last_index(index_to_try)
    loop do
      open_store(index_to_try)
      if @store.size < MAXSIZE
        return
      end
      index_to_try += 1
    end
  end
end
