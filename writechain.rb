class WriteChain
  def initialize(child, options={})
    @child = child
  end

  def self.create(kind,options)
    storedir = "store"
    if kind == :network
      require 'blobcrypt'
      require 'keyify'
      require 'compress'
      require 'writecheck'
      require 'blobstorelocal'

      Compress.new(BlobCrypt.new(Keyify.new(WriteCheck.new(BlobStoreLocal.new(options))),options))
    elsif kind == :remote
      require 'segmented_datastore'
      require 'blobstore'
      require 'datastore'
      BlobStore.new(storedir,SegmentedDataStore.new("#{storedir}/blobdata",DataStore))
    elsif kind == :local
      require 'blobcrypt'
      require 'keyify'
      require 'compress'
      require 'writecheck'

      Compress.new(BlobCrypt.new(Keyify.new(WriteCheck.new(create(:remote,options))),options))
    else
      raise "Do not know how to create WriteChain #{kind}"
    end
  end

  # read_sha and write should be implemented by the derived class.
  def read_sha(sha)
    @child.read_sha(sha)
  end

  def write(data)
    @child.write(data)
  end


  def close
    @child.close
  end

  def has_sha?(sha)
    @child.has_sha?(sha)
  end

  def write_commit(sha,message)
    @child.write_commit(sha,message)
  end


end
