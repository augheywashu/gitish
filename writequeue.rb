require 'writechain'
require 'countingsemaphore'
require 'thread'

class WriteQueue < WriteChain
  def initialize(child,options)
    super
    @writesem = CountingSemaphore.new(100)
    @readsem = CountingSemaphore.new(0)
    @syncsignal = CountingSemaphore.new(0)
    @queuelock = Mutex.new
    @childlock = Mutex.new
    @writequeue = []

    Thread.new do
      handle_write
    end
  end

  def write(data,sha)
    raise "WriteQueue: sha must be defined in write" if sha.nil?
#    STDERR.puts "waiting for write sem"
    @writesem.wait

#    STDERR.puts "waiting for queue lock"
    @queuelock.lock
    @writequeue.push([data + "",sha + ""])
#    STDERR.puts "Write queue depth #{@writequeue.size} #{data.size} #{sha}"
    @queuelock.unlock
#    STDERR.puts "ul"

    @readsem.signal
#    STDERR.puts "done queueing #{sha}"
    return sha
  end

  def sync
    # Wait for the writes to finish
#    STDERR.puts "In SYNC"

    @queuelock.lock
    if @writequeue.empty?
      empty = true
    else
      empty = false
      @signalsync = true
    end
    @queuelock.unlock

    if not empty
      STDERR.puts "WriteQueue: waiting for write thread to finish"
      @syncsignal.wait
    end
    @childlock.lock
    @child.sync
    @childlock.unlock
    STDERR.puts "WriteQueue: sunk"
  end

  def read_sha(sha)
    @childlock.lock
    res = super
    @childlock.unlock
    res
  end

  def has_shas?(shas, skip_cache)
    @childlock.lock
    res = super
    @childlock.unlock
    res
  end

  def close
    # STDERR.puts "WriteQueue closing"
    self.sync
    @childlock.lock
    @child.close
    @childlock.unlock

    @exit = true
    @readsem.signal
    @readsem.wait
  end

  def write_commit(sha,message)
    @childlock.lock
    res = super
    @childlock.unlock
    res
  end

  protected

  def handle_write
#    STDERR.puts "WriteQueue::handle_write starting"
    loop do
      # STDERR.puts "WriteQueue::handle_write waiting for more data"
      @readsem.wait

      if @exit
        @readsem.signal
        break
      end

      @queuelock.lock
      data,sha = @writequeue.pop
      @queuelock.unlock

      #      STDERR.puts "WriteQueue: Passing #{sha} #{data.size} on to child"
      @childlock.lock
      begin
        @child.write(data,sha)
      ensure
        @childlock.unlock
        #      STDERR.puts "WriteQueue: Done Passing #{sha} #{data.size} on to child"

        @queuelock.lock
        if @writequeue.empty? and @signalsync
          @signalsync = false
          #        STDERR.puts "WriteQueue signaling sync"
          @syncsignal.signal
        end
        @queuelock.unlock

        #      STDERR.puts "handle_write: signaling write semaphore"

        @writesem.signal
      end
    end
  end
end
