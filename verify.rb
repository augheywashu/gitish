require 'commandline'
require 'backuphandler'

class BackupHandler
  attr_reader :archive
  def initialize(archive)
    @archive = archive
  end

  def verify_dir(sha,path)
    STDERR.puts "Verifying directory #{path} #{sha}"

    info = archive.read_directory(sha)
    for dirname,dirinfo in info[:dirs]
      verify_dir(dirinfo[:sha],File.join(path,dirname))
    end
    for filename,info in info[:files]
      fullpath = File.join(path,filename)
      STDERR.puts "Verifying file #{fullpath}"
      filesha = info[:sha]
      # Now the sha is really a pointer to more shas
      for sha in archive.dereferenced_fileshas(filesha)
        data = archive.read_sha(sha)
      end
    end
  end
end

CommandLine.create(ARGV) do |archive,sha,options|
  handler = BackupHandler.new(archive)

  handler.verify_dir(sha,"")
  archive.sync
  puts "Done with verify"
end

exit 0
