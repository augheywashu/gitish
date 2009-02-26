require 'digest/sha1'
require 'yaml'

class Archive
  class ShaNotFound < Exception
    def initialize(info)
      super(info)
    end
  end
  class ShortRead < Exception
    def initialize(info)
      super(info)
    end
  end

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

  def sync
    @blobstore.sync
  end

  def write_file(path,stat)
    size = stat.size
    STDERR.puts "Writing file #{path} (#{size.commaize} bytes)"

    numchunks = (size / CHUNKSIZE).ceil

    shas = []
    chunk = 0
    chunkmod = numchunks / 4
    bytesread = 0
    begin
      File.open(path,'r') do |f|
        until f.eof?
          data = f.read(CHUNKSIZE)
          bytesread += data.size
          if numchunks > 4 and chunk % chunkmod == 0
            STDERR.puts "Writing chunk #{chunk+1} of #{numchunks}"
          end
          @datasize += data.size
          sha = @blobstore.write(data,nil)
          shas << sha
          chunk += 1
        end
      end
      if shas.size == 1
        return shas.first
      else
        return "*" + @blobstore.write(shas.join("\n"),nil)
      end
    rescue Errno::ENOENT
      STDERR.puts "File #{path} has a funny character (haha), could not open."
      return nil
    rescue Errno::EACCES
      STDERR.puts "Could not access #{path}.  Not backed up."
      return nil
    end
    if bytesread != stat.size
      raise ShortRead.new("Expected to read #{stat.size}, actually read #{bytesread}")
    end
    filesha
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
    begin
      verify_shas!(info.all_shas)
    rescue ShaNotFound
      STDERR.puts info.inspect
      raise
    end
    @blobstore.write(info.to_yaml,nil)
  end

  def dereferenced_fileshas(sha)
    if sha[0,1] == '*'
      read_sha(sha[1,sha.size]).split("\n")
    else
      [sha]
    end
  end

  def write_commit(sha,message)
    STDERR.puts "Writing commit #{sha} - #{message}"
    @blobstore.write_commit(sha,message)
  end

  protected

  def verify_shas!(shas)
    # Strip the * off any shas that begin with one
    shas = shas.map{|s| s[0,1] == '*' ? s[1,s.size] : s}
    unless @blobstore.has_shas?(shas, :bypass_cache)
      STDERR.puts "sha in a list missing, looking for missed sha"
      for s in shas
        if @blobstore.has_shas?([s], :bypass_cache)
          STDERR.puts "#{s} is ok"
        else
          STDERR.puts "Could not find sha #{s}"
        end
      end

      raise ShaNotFound.new("Could not find #{shas.join(',')} in blobstore")
    end
  end

end

