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
    STDERR.puts "Writing file #{path} (#{size.commaize} bytes)"

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
    rescue Errno::ENOENT
      STDERR.puts "File #{path} has a funny character (haha), could not open."
      return nil
    rescue Errno::EACCES
      STDERR.puts "Could not access #{path}.  Not backed up."
      return nil
    end
    shas
  end

  def read_sha(sha)
    verify_shas!([sha])
    res = @blobstore.read_sha(sha)
    @readsize += res.size
    res
  end

  def read_directory(sha)
    YAML.load(read_sha(sha))
  end

  def write_directory(path,info)
    STDERR.puts "Writing directory #{path}"
    shas = []
    info.each_sha do |sha|
      shas << sha
    end
    verify_shas!(shas)
    @blobstore.write(info.to_yaml,nil)
  end

  def write_commit(sha,message)
    STDERR.puts "Writing commit #{sha} - #{message}"
    @blobstore.write_commit(sha,message)
  end

  protected

  def verify_shas!(shas)
    raise "Could not find #{sha} in blobstore" unless @blobstore.has_shas?(shas, :bypass_cache)
  end

end

