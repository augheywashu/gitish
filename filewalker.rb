require 'fileutils'

class FileWalker
  def initialize(options)
    if options['onlypatterns']
      @onlypatterns = options['onlypatterns']
    end

    @ignorefiles = options['ignorefiles'] ||
      ['.git','.svn','a.out','thumbs.db']


    @ignorepatterns = options['ignorepatterns'] ||
      [/^~/,
        /^\./,
        /\.o$/,
        /\.so$/,
        /\.a$/,
        /\.wav$/,
        /\.iso$/,
        /\.tmp$/]
    #/\.exe$/,
    #/\.mp3/,
    #/\.wma$/,
    #/\.avi$/,
    #/\.m4a$/,
    #/\.m4v$/,
    #/\.tif$/,
    #/\.mpg$/,

    @ignoredirpatterns = options['ignoredirpatterns'] || []

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
    for p in @ignoredirpatterns
      if p.match(path)
        return nil
      end
    end

    handler.begin_directory(path)

    begin
      files_to_process = []

      begin
        allentries = Dir.entries(path).sort
      rescue Exception => e
        STDERR.puts "FileWalker: Could not open directory #{path}.  Skipping"
        return nil
      end

      for e in allentries
        next if e == '.' or e == '..'
        downcase_e = e.downcase

        fullpath = File.join(path,e)
        begin
          stat = File.stat(fullpath)
        rescue
          STDERR.puts "FileWalker: Could not stat #{fullpath}, skipping"
          next
        end

        # Only do files or directories
        # Should we try following symlinks to files?
        # Should we try following symlinks to dirs?
        next unless stat.file? or stat.directory?

        if @ignorefiles.include?(downcase_e)
          skipfile(fullpath,stat)
          next
        end

        # Check the ignore patterns even before going into directories
        skip = false
        for p in @ignorepatterns
          if p.match(downcase_e)
            skip = true
            skipfile(fullpath,stat)
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
            skipfile(fullpath,stat)
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

  protected

  def skipfile(fullpath,stat)
    if stat.directory?
      @skippeddirs += 1
    else
      @skippedfiles += 1
      @skippedsize += stat.size
    end
  end

end

