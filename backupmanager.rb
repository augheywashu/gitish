require 'fileutils'
require 'gdbm'
require 'yaml'

# ctime -- In UNIX , it is not possible to tell the actual creation time of a file. The ctime--change time--is the time when changes were made to the file or directory's inode (owner, permissions, etc.). It is needed by the dump command to determine if the file needs to be backed up. You can view the ctime with the ls -lc command.

# atime -- The atime--access time--is the time when the data of a file was last accessed. Displaying the contents of a file or executing a shell script will update a file's atime, for example. You can view the atime with the ls -lu command.

# mtime -- The mtime--modify time--is the time when the actual contents of a file was last modified. This is the time displayed in a long directoring listing (ls -l).

class File
  class Stat
    def to_hash(mtime = self.mtime.to_i, ctime = self.ctime.to_i)
      { :mtime => mtime,
        :ctime => ctime,
        :gid => self.gid,
        :uid => self.uid,
        :mode => self.mode }
    end
  end
end

class BackupManager
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

  module CacheHelperMethods
    def each_sha
      for f,info in self[:files]
        for sha in info[:shas]
          yield sha
        end
      end
      for f,info in self[:dirs]
        yield info[:sha]
      end
    end

    def empty?
      self[:dirs].empty? and self[:files].empty?
    end

    def add_directory(name, sha, stat)
      self[:dirs][name] = { :sha => sha, :stat => stat.to_hash(nil,nil) }
    end

    def add_file(name, shas, stat)
      self[:files][name] = { :shas => shas, :stat => stat.to_hash }
    end

    def file_shas_for(file,stat)
      info = self[:files][file]

      return nil if info.nil?

      s = info[:stat]
      if s[:mtime] == stat.mtime.to_i and s[:ctime] == stat.ctime.to_i
        return info[:shas]
      else
        return nil
      end
    end
  end

  def empty_info
    ret = { :files => {}, :dirs => {} }
  end

  def save_info(path,info)
    @store[path] = info.to_yaml
  end

  def cache_for(path)
    values = @store[path]
    ret = nil
    if values
      ret = YAML.load(values)
    else
      ret = empty_info
    end
    ret.extend CacheHelperMethods
  end

  def archive_directory(path,archive)
    cache = cache_for(path)
    thisinfo = empty_info
    thisinfo.extend CacheHelperMethods

    ignorefiles = ['.','..','.git','.svn','a.out','0ld computers backed-up files here!','thumbs.db']
    ignorepatterns = [/^~/,/^\./,/\.o$/,/\.so$/,/\.a$/,/\.exe$/,/\.mp3/,
      /\.wav$/,
      /\.wma$/,
      /\.avi$/,
      /\.m4a$/,
      /\.m4v$/,
      /\.tif$/,
      /\.iso$/,
      /\.tmp$/,
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
          sha = archive_directory(fullpath,archive)
          if sha
            thisinfo.add_directory(e,sha,stat)
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
            next
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

        shas = cache.file_shas_for(e,stat)
        if shas.nil?
          shas = archive.write_file(fullpath,stat)
        end

        thisinfo.add_file(e,shas,stat)
      end
    rescue Exception => e
      STDERR.puts "Caught an exception #{e} while archiving #{path}"
      raise
    end

    # If this directory is empty, don't bother storing it.
    # The cache will be deleted by its parent.
    if thisinfo.empty?
      return nil
    end

    # Remember and remove the old cached sha
    cachedsha = cache[:sha]
    cache.delete(:sha)

    if thisinfo != cache
      sha = archive.write_directory(path,thisinfo)
      thisinfo[:sha] = sha
    end

    save_info(path,thisinfo)

    thisinfo[:sha]
  end

  def restore_dir(sha,archive,path)
    STDERR.puts "Restoring directory #{path} #{sha}"
    FileUtils.mkdir_p(path)

    info = archive.read_directory(sha)
    for dirname,dirinfo in info[:dirs]
      restore_dir(dirinfo[:sha],archive,File.join(path,dirname))
    end
    for filename,info in info[:files]
      fullpath = File.join(path,filename)
      STDERR.puts "Restoring file #{fullpath}"
      File.open(fullpath,"w") do |f|
        for sha in info[:shas]
          f.write(archive.read_sha(sha))
        end
      end
    end
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

