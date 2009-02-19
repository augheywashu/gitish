require 'digest/sha1'

class Archive
  CHUNKSIZE=1048576.0

  def initialize(blobstore)
    @blobstore = blobstore
  end

  def close
    @blobstore.close
  end

  def write_file(path)
    size = File.stat(path).size
    STDERR.puts "Writing file #{path} (#{size} bytes)"

    chunks = (size / CHUNKSIZE).ceil

    shas = []
    chunk = 1
    File.open(path,'r') do |f|
      until f.eof?
        data = f.read(CHUNKSIZE)
        sha = Digest::SHA1.hexdigest(data)
        STDERR.puts "Writing chunk #{chunk} of #{chunks}"
        @blobstore.write(data,sha) unless @blobstore.has_sha?(sha)
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
    @blobstore.read_directory(sha)
  end

  def write_directory(path,dirs,files)
    STDERR.puts "Writing directory #{path}"
    @blobstore.write_directory(dirs,files)
  end

  def write_commit(path,sha)
    STDERR.puts "Writing commit #{sha} - #{path}"
    @blobstore.write_commit(path,sha)
  end
end

