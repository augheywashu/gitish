require 'digest/sha1'
require 'yaml'

class Archive
  CHUNKSIZE=1048576.0

  def initialize(blobstore)
    @blobstore = blobstore
    @filecount = 0
    @datasize = 0
  end

  def stats
    ["Archive: wrote #{@filecount.commaize} files","Archive: wrote #{@datasize.commaize} bytes of file data"] + @blobstore.stats
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
    File.open(path,'r') do |f|
      until f.eof?
        data = f.read(CHUNKSIZE)
        if numchunks > 1 and chunk % chunkmod == 0
          STDERR.puts "Writing chunk #{chunk+1} of #{numchunks}"
        end
        @datasize += data.size
        sha = @blobstore.write(data)
        shas << sha
        chunk += 1
      end
    end
    shas.join(',')
  end

  def read_sha(sha)
    @blobstore.read_sha(sha)
  end

  def read_directory(sha)
    data = YAML.load(read_sha(sha))
    return data[0],data[1]
  end

  def write_directory(path,dirs,files)
    STDERR.puts "Writing directory #{path}"
    for info in dirs + files
      name,shas = info
      shas = "" unless shas
      verify_shas!(shas.split(','))
    end
    @blobstore.write([dirs,files].to_yaml)
  end

  def write_commit(sha,message)
    STDERR.puts "Writing commit #{sha} - #{message}"
    @blobstore.write_commit(sha,message)
  end

  protected

  def verify_sha!(sha)
    raise "Could not find #{sha} in blobstore" unless @blobstore.has_sha?(sha)
  end

  def verify_shas!(shas)
    for sha in shas
      verify_sha!(sha)
    end
  end

end

