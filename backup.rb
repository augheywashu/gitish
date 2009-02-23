require 'commandline'
require 'backuphandler'

CommandLine.create(ARGV) do |bm,path,options|
  handler = BackupHandler.new(bm.archive,options)

  sha = bm.archive_directory(path,handler)
  bm.archive.write_commit(sha,path + " - " + Time.now.to_s)
  puts sha

  handler.close
end

exit 0
