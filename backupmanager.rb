require 'gdbm'
require 'yaml'

class BackupManager
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

    onlypatterns = []
    ignorefiles = ['.','..','.git','.svn','a.out','0LD COMPUTERS BACKED-UP FILES HERE!']
    ignorepatterns = [/^~/,/^\./,/\.o$/,/\.so$/,/\.a$/]
  #  onlypatterns = [/\.doc/,/\.xls/]
    begin
      for e in Dir.entries(path).sort
        next if ignorefiles.include?(e)
        fullpath = File.join(path,e)
        # Strip off bad characters
        e.gsub!(/;/,'')

        stat = File.stat(fullpath)

        if File.directory?(fullpath)
          key = archive_directory(fullpath,archive)
          dirs << [e,key]
          cache.remember_dir(e,key,stat)
        else
          skip = false
          for p in ignorepatterns
            if p.match(e)
              skip = true
              break
            end
          end

          unless onlypatterns.empty?
            skip = true
            for p in onlypatterns
              if p.match(e)
                skip = false
                break
              end
            end
            next if skip
          end

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

end

