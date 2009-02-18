require 'digest/sha1'
require 'zlib'
require 'gdbm'
require 'yaml'

class BackupManager
  class Base
    def to_s
      @path
    end
  end

  class DirCache
    attr_accessor :key
    def initialize(path,store)
      @path = path
      @store = store

      @key,@filestats,@filekeys,@dirs = read(path)

      @newfilestats = { }
      @newfilekeys = { }
      @newdirs = { }
    end

    def save!
      # Remove all old files from the cache
      for removedir in @dirs.keys - @newdirs.keys
        recurse_remove(File.join(@path,removedir))
      end

      # Save our data into the cache
      write([key,@newfilestats,@newfilekeys,@newdirs])
    end

    def remember_dir(dir,key,stat)
      @newdirs[dir] = key
    end

    def remember_file(file,key,stat)
      @newfilestats[file] = stat.mtime
      @newfilekeys[file] = key
    end

    def key_for(file,stat)
      storedstat = @filestats[file]
      return nil if storedstat.nil?

      if storedstat == stat.mtime
        return @filekeys[file]
      else
        return nil
      end
    end

    def changed?
      if @key.nil?
        # We didn't have a key to begin with
        return true
      end

      if @newdirs != @dirs 
        puts "directory #{@path} changed because a directory changed"
        return true
      end
      if @newfilekeys != @filekeys
        puts "directory #{@path} changed because a file changed"
        return true
      end

      return false
    end

    protected

    def recurse_remove(path)
      puts "Recurse removing #{path}"
      key,filestats,filekeys,dirs = read(path)
      for dir in dirs.keys
        recurse_remove(File.join(path,dir))
      end
      @store.delete(path)
    end

    def write(data)
      @store[@path] = data.to_yaml
    end

    def read(path)
      if @store.has_key?(path)
        data = YAML.load(@store[path])
        return data[0],data[1],data[2],data[3]
      else
        return nil,{ },{ },{ }
      end
    end

  end

  def initialize
    @store = GDBM.new("cache.db")
  end

  def close
    @store.close
  end

  def cache_for(path)
    DirCache.new(path,@store)
  end

  def archive_directory(path,archive)
    files = []
    dirs = []

    cache = cache_for(path)

    begin
    for e in Dir.entries(path)
      next if e == '.' or e == '..'

      fullpath = File.join(path,e)

      stat = File.stat(fullpath)

      if File.directory?(fullpath)
        key = archive_directory(fullpath,archive)
        dirs << [e,key]
        cache.remember_dir(e,key,stat)
      else
        key = cache.key_for(e,stat)
        if key.nil?
          key = archive.write_file(fullpath)
        end

        files << [e,key]

        cache.remember_file(e,key,stat)
      end
    end
    rescue Exception => e
      puts "Caught an exception #{e} while archiving #{path}"
      raise
    end

    if cache.changed?
      key = archive.write_directory(path,dirs,files)
      cache.key = key
    end

    cache.save!

    cache.key
  end


  def changed_directories(path = @path,&block)
    files = []
    dirs = []
    for e in Dir.entries(path)

      fullpath = File.join(path,e)

      if File.directory?(fullpath)
        dirs << fullpath
        changed_directories(fullpath,&block)
      else
        files << fullpath
      end
    end
    block.call(Directory.new(self,path,dirs,files))
  end

end

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

  def write(data,sha = nil)
    sha = Digest::SHA1.hexdigest(data) unless sha
    unless @blobs.has_key?(sha)
      storekey = @store.write(data)
      @blobs[sha] = storekey.to_s
    end
    sha
  end
end

class DataStore
  def initialize(file)
    @file = File.open(file,"ab+")
    @file.seek(0,IO::SEEK_END)
  end

  def close
    @file.close
  end

  def size
    @file.tell
  end

  def write(data)
    @file.seek(0,IO::SEEK_END)
    out = Zlib::Deflate.deflate(data)
    offset = @file.tell
    @file.write out
    @file.fsync
    offset
  end
end

class Archive
  def initialize
    @store = BlobStore.new(DataStore.new("rawdata"))
  end

  def close
    @store.close
  end

  def write_file(path)
    puts "Writing file #{path}"

    shas = []
    File.open(path,'r') do |f|
      until f.eof?
        data = f.read(1048576)
        sha = Digest::SHA1.hexdigest(data)
        @store.write(data,sha) unless @store.has_sha?(sha)
        shas << sha
      end
    end
    shas.join(',')
  end

  def write_directory(path,dirs,files)
    puts "Writing directory #{path}"
    @store.write([dirs,files].to_yaml)
  end

  def write_commit(dir)
    puts "(not) Writing commit #{dir}"
  end
end

bm = BackupManager.new
archive = Archive.new

begin
  key = bm.archive_directory(ARGV[0],archive)
  archive.write_commit(key)
ensure
  bm.close
  archive.close
end
