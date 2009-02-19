require 'backupmanager'
require 'archive'
require 'writechain'

bm = BackupManager.new
archive = Archive.new(WriteChain.create(ARGV[0].to_sym,eval(ARGV[1])))

ARGV.shift
ARGV.shift

begin
  for path in ARGV
    sha = bm.archive_directory(path,archive)
    archive.write_commit(sha,path + " - " + Time.now.to_s)
    puts sha
  end
ensure
  bm.close
  archive.close

  STDERR.puts archive.stats.join("\n")
end
