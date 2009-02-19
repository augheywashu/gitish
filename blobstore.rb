require 'gdbm'
require 'digest/sha1'
require 'blobcrypt'
require 'fileutils'

class BlobStore
  def initialize(store,options)
    @storedir = options[:storedir] || raise("BlobStore: :storedir option not defined")
    FileUtils::mkdir_p(@storedir)
    @store = store
    @blobs = GDBM.new(File.join(@storedir,"blobs.db"))
    @flatdb = File.open(File.join(@storedir,"blobs.txt"),"a+")
    @datasize = 0
  end

  def stats
    ["BlobStore: write #{@datasize.commaize} bytes to the store"]
  end

  def close
    @blobs.close
    @store.close
  end

  def has_sha?(sha)
    @blobs.has_key?(sha)
  end

  def write_commit(sha,message)
    verify_sha!(sha)
    File.open(File.join(@storedir,"commits"),'a+') do |f|
      f.puts "#{sha} - #{message}"
    end
  end

  def read_sha(sha)
    verify_sha!(sha)
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

  def verify_sha!(sha)
    raise "Could not find #{sha} in blobstore" unless self.has_sha?(sha)
  end
end

