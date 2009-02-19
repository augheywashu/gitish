require 'remotecommon'
require "open3"

class BlobStoreLocal
  include RemoteCommon

  def initialize(command)
    @stdin,@stdout,@stderr = Open3.popen3(command)

    @stdin.sync = true
    @stdout.sync = true
    @stderr.sync = true
  end

  def read_directory(sha)
    @stdin.puts "readdir #{sha}"
    dirs,files = read_dirs_files(@stdout)
    return dirs,files
  end

  def close
    @stdin.close
    @stdout.close
    @stderr.close
  end

  def has_sha?(sha)
    @stdin.puts "sha?"
    @stdin.puts sha
    res = @stdout.readline.chomp
    return res == 1
  end

  def read_sha(sha)
    @stdin.puts "readsha #{sha}"
    size = @stdout.readline.chomp.to_i
    @stdout.read(size)
  end

  def write_directory(dirs,files)
    @stdin.puts "dir"
    write_dirs_files(@stdin,dirs,files)
    @stdout.readline.chomp
  end

  def write_commit(path,sha)
    @stdin.puts "commit #{sha} #{path}"
    @stdout.readline.chomp
  end

  def write(data,sha = nil)
    @stdin.puts "data #{data.size}"
    @stdin.write(data)
    returnedsha = @stdout.readline.chomp
    if !sha.nil?
      raise "Hmmmm, wrote data with sha #{sha} and server returned #{returnedsha}" if returnedsha != sha
    end
    returnedsha
  end
end
