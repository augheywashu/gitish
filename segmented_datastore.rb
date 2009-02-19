class SegmentedDataStore
  MAXSIZE = 40000
  def initialize(filebase,storeclass)
    @filebase = filebase
    @storeclass = storeclass
    @index = 0

    open_last_index
  end

  def write(data)
    if @store.size > MAXSIZE
      @store.close
      @index += 1
      open_last_index
    end
    key = @store.write(data)
    # Prepend the index number to the key
    "#{@index}-#{key}"
  end

  def read(key)
    key=~/^(\d)-(.*)/
    open_store($1)
    @store.read($2)
  end

  def method_missing(method, *args)
    @store.send(method,*args)
  end

  protected

  def open_store(index)
    @store.close if @store
    filename = sprintf("#{@filebase}-%03d",@index)
    @store = @storeclass.new(filename)
  end

  def open_last_index
    loop do
      open_store(@index)
      if @store.size < MAXSIZE
        return
      end
      @index += 1
    end
  end
end
