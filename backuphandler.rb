require 'handler'
require 'fileutils'

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

class BackupHandler < Handler
  attr_reader :archive
  def initialize(archive,options)
    @archive = archive

    cachefile = options['cachefile'] || raise("BackupManager: :cachefile option missing")

    @cachedb = GDBM.new(cachefile)
    @cachestack = []
    @infostack = []
  end

  def close
    @cachedb.close
  end

  def begin_directory(path)
    push

    @cache = cache_for(path)
    @thisinfo = empty_info
    @thisinfo.extend CacheHelperMethods
  end

  def add_directory(e,fullpath,stat,ret)
    # if ret doesn't exist, we don't keep this directory
    return unless ret

    @thisinfo.add_directory(e,ret,stat)
  end

  def process_file(e,fullpath,stat)
    shas = @cache.file_shas_for(e,stat)
    if shas.nil?
      shas = @archive.write_file(fullpath,stat)
    end

    @thisinfo.add_file(e,shas,stat) if shas
  end

  def end_directory(path)
    # If this directory is empty, don't bother storing it.
    # The cache will be deleted by its parent.
    if @thisinfo.empty?
      pop
      return nil
    end

    # Remember and remove the old cached sha
    cachedsha = @cache[:sha]
    @cache.delete(:sha)

    if @thisinfo != @cache
      begin
        sha = @archive.write_directory(path,@thisinfo)
      rescue Archive::ShaNotFound
        puts "Removing #{path} from the cachedb because of the exception"
        for d,info in @thisinfo[:dirs]
          recurse_delete(File.join(path,d))
        end
        recurse_delete(path)
        raise
      end

      @thisinfo[:sha] = sha
      save_info(path,@thisinfo)
    else
      @thisinfo[:sha] = cachedsha
    end

    sha = @thisinfo[:sha]
    pop
    sha
  end

  def restore_dir(sha,path)
    STDERR.puts "Restoring directory #{path} #{sha}"
    FileUtils.mkdir_p(path)

    info = archive.read_directory(sha)
    for dirname,dirinfo in info[:dirs]
      restore_dir(dirinfo[:sha],File.join(path,dirname))
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

  def recurse_delete(path)
    STDERR.puts "BackupHandler: removing #{path} from the cache"
    info = cache_for(path)
    return if info.nil?
    for dir,info in info[:dirs]
      recurse_delete(File.join(path,dir))
    end
    @cachedb.delete(path)
  end

  def push
    @cachestack.push(@cache)
    @infostack.push(@thisinfo)
  end

  def pop
    @cache = @cachestack.pop
    @thisinfo = @infostack.pop
  end

  module CacheHelperMethods
    def all_shas
      shas = []
      for f,info in self[:files]
        shas += info[:shas]
      end
      for f,info in self[:dirs]
        shas << info[:sha]
      end
      shas
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
    @cachedb[path] = info.to_yaml
  end

  def cache_for(path)
    values = @cachedb[path]
    ret = nil
    if values
      ret = YAML.load(values)
    else
      ret = empty_info
    end
    ret.extend CacheHelperMethods
  end

end
