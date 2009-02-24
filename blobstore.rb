require 'gdbm'
require 'digest/sha1'
require 'blobcrypt'
require 'fileutils'

class BlobStore
  def initialize(store,options)
    @storedir = options['storedir'] || raise("BlobStore: storedir option not defined")
    FileUtils::mkdir_p(@storedir)
    @store = store
    @blobs = GDBM.new(File.join(@storedir,"blobs.db"),0666,options['readonly'] ? GDBM::READER : (GDBM::WRCREAT | GDBM::SYNC))
    @flatdb = File.open(File.join(@storedir,"blobs.txt"),"a+") unless options['readonly']
    @datasize = 0
  end

  def stats
    ["BlobStore: wrote #{@datasize.commaize} bytes to the store"]
  end

  def close
    @blobs.close
    @store.close
  end

  def has_shas?(shas, skip_cache)
    for s in shas
      unless @blobs.has_key?(s)
        return false
      end
    end
    return true
  end

  def write_commit(sha,message)
    verify_shas!([sha])
    File.open(File.join(@storedir,"commits"),'a+') do |f|
      f.puts "#{sha} - #{message}"
    end
  end

  def read_sha(sha)
    @store.read(@blobs[sha])
  end

  def write(data,sha)
    raise "BlobStore: write should not be asked to write data it already has." if @blobs.has_key?(sha)
    @datasize += data.size
    storekey = @store.write(data)
    @blobs[sha] = storekey.to_s
    @flatdb.flock File::LOCK_EX
    @flatdb.puts "#{sha} #{storekey.to_s}"
    @flatdb.sync
    @flatdb.flock File::LOCK_UN
    sha
  end

  protected

  def verify_shas!(shas)
    raise "Could not find #{sha} in blobstore" unless self.has_shas?(shas,:bypass_cache)
  end
end

