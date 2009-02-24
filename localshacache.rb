require 'writechain'
require 'gdbm'

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
    else
      sha = [sha] unless sha.is_a?(Array)
      for s in sha
        unless @cache.has_key?(s)
          return super
        end
        return true
      end
    end
  end

  def close
    @cache.close
    super
  end
end
