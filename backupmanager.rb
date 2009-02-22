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
        # STDERR.puts "directory #{@path} changed because a directory changed"
        return true
      end
      if @newfilekeys != @filekeys
        # STDERR.puts "directory #{@path} changed because a file changed"
        return true
      end

      return false
    end

    protected

    def recurse_remove(path)
      # STDERR.puts "Recurse removing #{path}"
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

  def initialize(options)
    cachefile = options['cachefile'] || raise("BackupManager: :cachefile option missing")
    if options['onlypatterns']
      @onlypatterns = options['onlypatterns']
    end
    @store = GDBM.new(cachefile)
    @lookcount = 0
    @looksize = 0
    @skippeddirs = 0
    @skippedfiles = 0
    @skippedsize = 0
  end

  def stats
    ["BackupManager: Looked at #{@lookcount.commaize} files.",
      "BackupManager: Looked at #{@looksize.commaize} bytes.",
      "BackupManager: skipped #{@skippeddirs.commaize} directories.",
      "BackupManager: skipped #{@skippedfiles.commaize} files.",
      "BackupManager: skipped #{@skippedsize.commaize} bytes (of skipped files)."]
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

    ignorefiles = ['.','..','.git','.svn','a.out','0ld computers backed-up files here!','thumbs.db']
    ignorepatterns = [/^~/,/^\./,/\.o$/,/\.so$/,/\.a$/,/\.exe$/,/\.mp3/,
      /\.wav$/,
      /\.wma$/,
      /\.avi$/,
      /\.m4a$/,
      /\.m4v$/,
      /\.tif$/,
      /\.iso$/,
      /\.mpg$/]

    begin
      files_to_process = []
      for e in Dir.entries(path).sort
        downcase_e = e.downcase

        fullpath = File.join(path,e)
        stat = File.stat(fullpath)

        # Only do files or directories
        # Should we try following symlinks to files?
        # Should we try following symlinks to dirs?
        next unless stat.file? or stat.directory?

        if ignorefiles.include?(downcase_e)
          skipfile(stat)
          next
        end

        # Strip off bad characters
        e.gsub!(/;/,'')

        # Check the ignore patterns even before going into directories
        skip = false
        for p in ignorepatterns
          if p.match(downcase_e)
            skip = true
            skipfile(stat)
            break
          end
        end

        next if skip

        if File.directory?(fullpath)
          key = archive_directory(fullpath,archive)
          if key
            dirs << [e,key]
            cache.remember_dir(e,key,stat)
          end
        else
          # Check for only patterns if they exist
          if @onlypatterns
            skip = true
            for p in @onlypatterns
              if p.match(downcase_e)
                skip = false
                break
              end
            end
          end

          if skip
            skipfile(stat)
          end

          # Keep a list of the files to do after directories.
          # We do the files afterwards to reduce re-writes on aborts
          files_to_process << [e,fullpath,stat]
        end
      end # for all dir entries

      # Now do the files.
      for f in files_to_process
        e,fullpath,stat = f

        @lookcount += 1
        @looksize += stat.size

        key = cache.key_for(e,stat)
        if key.nil?
          key = archive.write_file(fullpath,stat)
        end

        files << [e,key]

        cache.remember_file(e,key,stat)
      end
    rescue Exception => e
      STDERR.puts "Caught an exception #{e} while archiving #{path}"
      raise
    end

    # If this directory is empty, don't bother storing it.
    # The cache will be deleted by its parent.
    if dirs.empty? and files.empty?
      return nil
    end

    if cache.changed?
      key = archive.write_directory(path,dirs,files)
      cache.key = key
    end

    cache.save!

    cache.key
  end

  protected

  def skipfile(stat)
    if stat.directory?
      @skippeddirs += 1
    else
      @skippedfiles += 1
      @skippedsize += stat.size
    end
  end

end

