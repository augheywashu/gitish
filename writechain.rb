module Comma
  def commaize
    self.to_s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')
  end
end

Bignum.send :include,Comma
Fixnum.send :include,Comma

class WriteChain
  def initialize(child, options={})
    @child = child
  end

  def stats
    @child.stats
  end

  def self.create(kind,options)
    if kind == :network
      require 'blobcrypt'
      require 'keyify'
      require 'compress'
      require 'writecheck'
      require 'localshacache'
      require 'blobstorelocal'

      Compress.new(BlobCrypt.new(Keyify.new(WriteCheck.new(LocalSHACache.new(BlobStoreLocal.new(options),options),options),options),options),options)
      #Compress.new(BlobCrypt.new(Keyify.new(WriteCheck.new(BlobStoreLocal.new(options),options),options),options),options)
    elsif kind == :remote
      require 'segmented_datastore'
      require 'blobstore'
      require 'datastore'
      BlobStore.new(SegmentedDataStore.new(DataStore,options),options)
    elsif kind == :local
      require 'blobcrypt'
      require 'keyify'
      require 'compress'
      require 'writecheck'
      require 'localshacache'

      Compress.new(BlobCrypt.new(Keyify.new(WriteCheck.new(create(:remote,options),options),options),options),options)
    else
      raise "Do not know how to create WriteChain #{kind}"
    end
  end

  # read_sha and write should be implemented by the derived class.
  def read_sha(sha)
    @child.read_sha(sha)
  end

  def write(data,sha=nil)
    ret = @child.write(data,sha)
    if sha
      raise "WriteChain: child didn't return the same sha given.  #{sha} != #{ret}" if sha != ret
    end
    ret
  end


  def close
    @child.close
  end

  def has_shas?(shas, skip_cache)
    @child.has_shas?(shas, skip_cache)
  end

  def write_commit(sha,message)
    @child.write_commit(sha,message)
  end


end
