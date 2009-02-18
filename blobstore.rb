require 'gdbm'
require 'yaml'
require 'digest/sha1'

class BlobStore
  def initialize(store)
    @store = store
    @blobs = GDBM.new("blobs.db")
  end

  def close
    @blobs.close
    @store.close
  end

  def has_sha?(sha)
    @blobs.has_key?(sha)
  end

  def verify_sha!(sha)
    raise "Could not find #{sha} in blobstore" unless self.has_sha?(sha)
  end

  def verify_shas!(shas)
    for sha in shas
      verify_sha!(sha)
    end
  end

  def write_directory(dirs,files)
    for info in dirs + files
      name,shas = info
      verify_shas!(shas.split(','))
    end
    self.write([dirs,files].to_yaml)
  end

  def read_directory(sha)
    data = YAML.load(read_sha(sha))
    return data[0],data[1]
  end

  def read_sha(sha)
    verify_sha!(sha)
    @store.read(@blobs[sha])
  end

  def write_commit(path,sha)
    verify_sha!(sha)
    File.open("commits",'a+') do |f|
      f.puts "#{sha} - #{path} - #{Time.now}"
    end
  end

  def write(data,sha = nil)
    sha = Digest::SHA1.hexdigest(data) unless sha
    unless @blobs.has_key?(sha)
      storekey = @store.write(data)
      @blobs[sha] = storekey.to_s
    end
    sha
  end
end

