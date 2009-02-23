require 'digest/sha1'
require 'yaml'

class Archive
  CHUNKSIZE=1048576.0

  def initialize(blobstore)
    @blobstore = blobstore
    @filecount = 0
    @datasize = 0
    @readsize = 0
  end

  def stats
    ["Archive: wrote #{@filecount.commaize} files",
      "Archive: wrote #{@datasize.commaize} bytes of file data",
      "Archive: read #{@readsize.commaize} bytes"] + @blobstore.stats
  end

  def close
    @blobstore.close
  end

  def write_file(path,stat)
    size = stat.size
    STDERR.puts "Writing file #{path} (#{size} bytes)"

    numchunks = (size / CHUNKSIZE).ceil

    shas = []
    chunk = 0
    chunkmod = numchunks / 4
    begin
    File.open(path,'r') do |f|
      until f.eof?
        data = f.read(CHUNKSIZE)
        if numchunks > 4 and chunk % chunkmod == 0
          STDERR.puts "Writing chunk #{chunk+1} of #{numchunks}"
        end
        @datasize += data.size
        sha = @blobstore.write(data,nil)
        shas << sha
        chunk += 1
      end
    end
    rescue Errno::EACCES
      STDERR.puts "Could not access #{path}.  Not backed up."
      return nil
    end
    shas
  end

  def read_sha(sha)
    verify_sha!(sha)
    res = @blobstore.read_sha(sha)
    @readsize += res.size
    res
  end

  def read_directory(sha)
    YAML.load(read_sha(sha))
  end

  def write_directory(path,info)
    STDERR.puts "Writing directory #{path}"
    info.each_sha do |sha|
      verify_sha!(sha)
    end
    @blobstore.write(info.to_yaml,nil)
  end

  def write_commit(sha,message)
    STDERR.puts "Writing commit #{sha} - #{message}"
    @blobstore.write_commit(sha,message)
  end

  protected

  def verify_sha!(sha)
    raise "Could not find #{sha} in blobstore" unless @blobstore.has_sha?(sha, :bypass_cache)
  end

  def verify_shas!(shas)
    for sha in shas
      verify_sha!(sha)
    end
  end

end

