require 'rubygems'
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

      @key = read('key',nil)

      @dirs = read('dirs',{ })
      @files = read('files',{ })

      @newdirs = { }
      @newfiles = { }
    end

    def save!
      # Remove all old files from the cache
      for removeddir in @dirs.keys - @newdirs.keys
        recurse_remove(File.join(@path,removedir))
      end

      # Save our data into the cache
      @store['dirs' + @path] = @newdirs.to_yaml
      @store['files' + @path] = @newdirs.to_yaml
      @store['key' + @path] = self.key
    end

    def remember_dir(dir,key,stat)
      @newdirs[dir] = [key,stat]
    end

    def remember_file(file,key,stat)
      @newfiles[file] = [key,stat]
    end

    def key_for(file,stat)
      values = @files[file]
      return nil if values.nil?

      if values[1] == stat
        return values[0]
      else
        return nil
      end
    end

    def changed?
      if @key.nil?
        # We didn't have a key to begin with
        return true
      end

      if @newdirs != @dirs or @newfiles != @files
        return true
      end

      return false
    end

    protected

    def recurse_remove(path)
      puts "Recurse removing #{path}"
      dirs = read('dirs',{ },path)
      for dir in dirs.keys
        recurse_remove(File.join(path,dir))
      end
      @store.delete('dirs' + path)
      @store.delete('files' + path)
      @store.delete('key' + path)
    end

    def read(kind,default,path = @path)
      fullpath = kind + path
      if @store.has_key?(fullpath)
        return YAML.load(fullpath)
      else
        return default
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

    if cache.changed?
      key = archive.write_directory(path,dirs,files)
      cache.key = key
    end

    cache.save!

    key
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

class Archive
  def initialize
    @store = GDBM.new('archive.db')
  end

  def close
    @store.close
  end

  def write_file(path)
    puts "Writing file #{path}"
    path
  end
  def write_directory(path,dirs,files)
    puts "Writing directory #{path}"
    path
  end
  def write_commit(dir)
  end
end

bm = BackupManager.new
archive = Archive.new

begin
  changed,key = bm.archive_directory(ARGV[0],archive)
ensure
  bm.close
  archive.close
end
