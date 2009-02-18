require 'blobstore'
require 'datastore'

store = BlobStore.new(DataStore.new("rawdata"))

log = File.open("log","w")
$log = log

STDIN.sync = true
STDOUT.sync = true
STDERR.sync = true

begin
  until STDIN.eof?
    command = STDIN.readline.chomp
    log.puts "got #{command}"
    if command == 'sha?'
      sha = STDIN.readline.chomp
      if store.has_sha?(sha)
        puts "1"
      else
        puts "0"
      end
    elsif command == 'dir'
      dirs = []
      files = []
      until (line = STDIN.readline.chomp) == ""
        log.puts "dir line #{line}"
        action,name,shas = line.split(';')
        if action == 'd'
          dirs << [name,shas]
        elsif action == 'f'
          files << [name,shas]
        else
          raise "unknown action in dir line #{action}"
        end
      end
      log.puts dirs.inspect
      log.puts files.inspect
      puts store.write_directory(dirs,files)
    elsif command=~/commit (\w+)(.*)/
      store.write_commit($2,$1)
      puts "done"
    elsif command=~/data (\d+)/
      data = STDIN.read($1.to_i)
      puts store.write(data)
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
