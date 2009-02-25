require 'thread'
#
# $Id: semaphore.rb,v 1.2 2003/03/15 20:10:10 fukumoto Exp $
#

class CountingSemaphore

  def initialize(initvalue = 0)
    @counter = initvalue
    @waiting_list = []
    @lock = Mutex.new
  end

  def wait(max = nil)
    @lock.lock
    if (@counter -= 1) < 0
      @waiting_list.push(Thread.current)
      if max && @waiting_list.size == max
        (@waiting_list.size-1).times do
          self.signal
        end
        @lock.unlock
        return nil
      end
      @lock.unlock
      Thread.stop
    else
      @lock.unlock
    end
    self
  end

  def signal
    @lock.lock
    begin
      if (@counter += 1) <= 0
        t = @waiting_list.shift
        t.wakeup if t
      end
    rescue ThreadError
      retry
    end
    self
  ensure
    @lock.unlock
  end

  alias down wait
  alias up signal
  alias P wait
  alias V signal

  def exclusive
    wait
    yield
  ensure
    signal
  end

  alias synchronize exclusive

end
