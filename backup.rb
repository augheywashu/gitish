require 'commandline'
require 'backuphandler'
require 'filewalker'

CommandLine.create(ARGV) do |archive,path,options|
  handler = BackupHandler.new(archive,options)
  walker = FileWalker.new(options)

  begin
    sha = walker.walk_directory(path,handler)
    archive.sync
    archive.write_commit(sha,(options['message'] || "") + path + " - " + Time.now.to_s)
    archive.sync
    puts sha
  ensure
    STDERR.puts "Done with #{path}"
    archive.sync
    handler.close
  end

  STDERR.puts walker.stats.join("\n")
end

exit 0
