require 'writechain'

class NullIO
  def puts(*args)
  end
  def sync=(val)
  end
end

if ENV["LOG_IO"]
  log = File.open("log","w")
else
  log = NullIO.new
end

begin

  store = WriteChain.create(:remote,{ })

  STDIN.sync = true
  STDOUT.sync = true
  STDERR.sync = true
  log.sync = true

  until STDIN.eof?
    command = STDIN.readline.chomp
    log.puts "got #{command}"
    if command=~/sha\? (.*)/
      if store.has_sha?($1)
        puts "1"
      else
        puts "0"
      end
    elsif command=~/readsha (\w+)/
      data = store.read_sha($1)
      puts data.size
      STDOUT.write(data)
    elsif command=~/commit (\w+)(.*)/
      store.write_commit($1,$2)
      puts "done"
    elsif command=~/write (\w+) (\d+)/
      data = STDIN.read($2.to_i)
      puts store.write(data,$1)
    else
      raise "unknown command received #{command}"
    end
  end
rescue Exception => e
  log.puts "Caught exception #{e}"
  log.puts e.backtrace.join("\n")
ensure
  store.close
end
