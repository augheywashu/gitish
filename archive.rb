require 'digest/sha1'

class Archive
  def initialize(blobstore)
    @blobstore = blobstore
  end

  def close
    @blobstore.close
  end

  def write_file(path)
    STDERR.puts "Writing file #{path}"

    shas = []
    File.open(path,'r') do |f|
      until f.eof?
        data = f.read(1048576)
        sha = Digest::SHA1.hexdigest(data)
        @blobstore.write(data,sha) unless @blobstore.has_sha?(sha)
        shas << sha
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

