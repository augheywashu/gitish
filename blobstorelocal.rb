require "open3"

class BlobStoreLocal

  def initialize(options)
    command = options[:remote_command] || raise("BlobStoreLocal: :remote_command not defined in options")
    @stdin,@stdout,@stderr = Open3.popen3(command)

    @stdin.sync = true
    @stdout.sync = true
    @stderr.sync = true
  end

  def close
    @stdin.close
    @stdout.close
    @stderr.close
  end

  def has_sha?(sha)
    @stdin.puts "sha? #{sha}"
    res = @stdout.readline.chomp.to_i
    return res == 1
  end

  def read_sha(sha)
    @stdin.puts "readsha #{sha}"
    size = @stdout.readline.chomp.to_i
    @stdout.read(size)
  end

  def write_commit(sha,message)
    @stdin.puts "commit #{sha} #{message}"
    @stdout.readline.chomp
  end

  def write(data,sha)
    @stdin.puts "write #{sha} #{data.size}"
    @stdin.write(data)
    returnedsha = @stdout.readline.chomp
    if !sha.nil?
      raise "Hmmmm, wrote data with sha #{sha} and server returned #{returnedsha}" if returnedsha != sha
    end
    returnedsha
  end
end
