module RemoteCommon
  def read_dirs_files(io)
    dirs = []
    files = []
    until (line = io.readline.chomp) == ""
      action,name,shas = line.split(';')
      if action == 'd'
        dirs << [name,shas]
      elsif action == 'f'
        files << [name,shas]
      else
        raise "unknown action in dir line #{action}"
      end
    end
    return dirs,files
  end

  def write_dirs_files(io,dirs,files)
    for dir in dirs
      io.puts "d;" + dir.join(";")
    end
    for file in files
      io.puts "f;" + file.join(";")
    end
    io.puts
  end
end
