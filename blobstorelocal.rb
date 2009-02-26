require "open3"

class BlobStoreLocal
  def initialize(child,options)
    raise "BlobStoreLocal: child really must be nil" unless child.nil?

    command = options['remote_command'] || raise("BlobStoreLocal: remote_command not defined in options")
    @stdin,@stdout,@stderr = Open3.popen3(command)

    @stdin.sync = true
    @stdout.sync = true
    @stderr.sync = true

    @writesize = 0
    @readsize = 0
  end

  def stats
    ["BlobStoreLocal: wrote #{@writesize.commaize} bytes",
      "BlobStoreLocal: read #{@readsize.commaize} bytes"]
  end

  def close
    @stdin.close
    @stdout.close
    @stderr.close
  end

  def has_shas?(shas, skip_cache)
    puts "sha? #{shas.join(',')}"
    res = readline.chomp.to_i
    return res == 1
  end

  def sync
    puts "sync"
    readline
  end

  def read_sha(sha)
    puts "readsha #{sha}"
    size = readline.chomp.to_i
    read(size)
  end

  def write_commit(sha,message)
    puts "commit #{sha} #{message}"
    readline.chomp
  end

  def write(data,sha)
    puts "write #{sha} #{data.size}"
    dowrite(data)
    returnedsha = readline.chomp
    if !sha.nil?
      raise "Hmmmm, wrote data with sha #{sha} and server returned #{returnedsha}" if returnedsha != sha
    end
    returnedsha
  end

  protected

  def puts(data)
    @writesize += data.size
    @stdin.puts data
  end

  def dowrite(data)
    @writesize += data.size
    @stdin.write(data)
  end

  def read(size)
    d = @stdout.read(size)
    @readsize += d.size
    d
  end

  def readline
    d = @stdout.readline
    @readsize += d.size
    d
  end

end
