require 'handler'

class VerifyHandler < Handler
  def initialize(path,archive,rootsha)
    @path = File.expand_path(path)
    @archive = archive
    @rootsha = rootsha
  end

  def process_file(e,fullpath,stat)
    puts "Verifying: #{fullpath}"

    # strip off the first part of the path
    archived_path = fullpath[@path.size,fullpath.size]

    shas = get_file_shas(archived_path)

    f = File.open(fullpath)
    for sha in shas
      archivedata  = @archive.read_sha(sha)
      filedata = f.read(archivedata.size)
      if archivedata != filedata
        raise "#{fullpath} differs between disk and archive (contents different)"
      end
    end
    raise "#{fullpath} differs between disk and archive (larger on disk)" unless f.eof?
    f.close
  end

  protected

  def get_file_shas(fullpath)
    dirname,filename = File.split(fullpath)

    if dirname == @lastdirname
      dir = @lastdir
    else
      dirs = dirname.split(File::SEPARATOR)

      dirsha = @rootsha
      for d in dirs
        next if d == '.'
        dir = @archive.read_directory(dirsha)
        raise "Could not get directory sha for #{dirsha} getting path #{fullpath} on directory #{d}" if dir.nil?
        entry = dir[:dirs][d]
        raise "Could not get directory entry sha for #{dirsha} getting path #{fullpath} on directory #{d}\n#{dir.inspect}" if entry.nil?
        dirsha = entry[:sha] || raise("Could not find directory name #{d} under sha #{sha} for directory #{fullpath}")
      end

      dir = @archive.read_directory(dirsha)
      raise "Could not read dirsha #{dirsha} for last entry of #{dirname}" if dir.nil?
      @lastdirname = dirname
      @lastdir = dir
    end

    fileentry = dir[:files][filename]
    raise "Could not find file entry for #{filename} in #{dirname}\n#{dir.inspect}" if fileentry.nil?

    @archive.dereferenced_fileshas(dir[:files][filename][:sha]) || raise("Could not find file shas for #{fullpath}")
  end

end
