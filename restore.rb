require 'commandline'
require 'backuphandler'

CommandLine.create(ARGV) do |archive,sha,options|
  handler = BackupHandler.new(archive,options)

  handler.restore_dir(sha,"restore")
end

exit 0
