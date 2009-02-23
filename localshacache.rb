require 'writechain'

class LocalSHACache < WriteChain
  def initialize(child,options = { })
    cachefile = options['localshacachefile'] || raise("LocalSHACache: localshacachefile option missing")
    @cache = GDBM.new(cachefile)
    super
  end

  def write(data,sha)
    returnedsha = super
    @cache[returnedsha] = "a"
    returnedsha
  end

  def has_sha?(sha, skip_cache)
    if skip_cache 
      super
    elsif @cache.has_key?(sha)
      return true
    else
      super
    end
  end

  def close
    @cache.close
    super
  end
end
