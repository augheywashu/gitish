require 'fileutils'

class FileWalker
  attr_reader :archive
  def initialize(options)
    if options['onlypatterns']
      @onlypatterns = options['onlypatterns']
    end

    @lookcount = 0
    @looksize = 0
    @skippeddirs = 0
    @skippedfiles = 0
    @skippedsize = 0
  end

  def stats
    ["FileWalker: Looked at #{@lookcount.commaize} files.",
      "FileWalker: Looked at #{@looksize.commaize} bytes.",
      "FileWalker: skipped #{@skippeddirs.commaize} directories.",
      "FileWalker: skipped #{@skippedfiles.commaize} files.",
      "FileWalker: skipped #{@skippedsize.commaize} bytes (of skipped files)."]
  end

  def walk_directory(path,handler)
    handler.begin_directory(path)

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
          ret = walk_directory(fullpath,handler)

          handler.add_directory(e,fullpath,stat,ret)
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

        handler.process_file(e,fullpath,stat)
      end

    rescue Exception => e
      STDERR.puts "Caught an exception #{e} while archiving #{path}"
      raise
    end

    handler.end_directory(path)
  end

  def verify_tree(sha,path,&block)
    STDERR.puts "Verifying directory #{sha}"
    info = archive.read_directory(sha)
    for dirname,dirinfo in info[:dirs]
      verify_tree(dirinfo[:sha],File.join(path,dirname),&block)
    end
    for filename,info in info[:files]
      fullpath = File.join(path,filename)
      yield fullpath,info[:shas]
    end
  end

  def read_sha(sha)
    archive.read_sha(sha)
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

