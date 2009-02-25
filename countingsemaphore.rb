#
# $Id: semaphore.rb,v 1.2 2003/03/15 20:10:10 fukumoto Exp $
#

class CountingSemaphore

  def initialize(initvalue = 0)
    @counter = initvalue
    @waiting_list = []
  end

  def wait(max = nil)
    Thread.critical = true
    if (@counter -= 1) < 0
      @waiting_list.push(Thread.current)
      if max && @waiting_list.size == max
        (@waiting_list.size-1).times do
          self.signal
        end
        return nil
      end
      Thread.stop
    end
    self
  ensure
    Thread.critical = false
  end

  def signal
    Thread.critical = true
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
    Thread.critical = false
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
