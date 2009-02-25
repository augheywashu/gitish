require 'commandline'
require 'backuphandler'
require 'filewalker'

CommandLine.create(ARGV) do |archive,path,options|
  handler = BackupHandler.new(archive,options)
  walker = FileWalker.new(options)

  begin
    sha = walker.walk_directory(path,handler)
    archive.sync
    archive.write_commit(sha,path + " - " + Time.now.to_s)
    puts sha
  ensure
    STDERR.puts "Done with #{path}"
    handler.close
  end

  STDERR.puts walker.stats.join("\n")
end

exit 0
