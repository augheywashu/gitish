require 'commandline'
require 'backuphandler'
require 'filewalker'

CommandLine.create(ARGV) do |archive,path,options|
  handler = BackupHandler.new(archive,options)
  walker = FileWalker.new(options)

  sha = walker.walk_directory(path,handler)
  archive.write_commit(sha,path + " - " + Time.now.to_s)
  puts sha

  STDERR.puts walker.stats.join("\n")
  handler.close
end

exit 0
