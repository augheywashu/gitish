require 'backupmanager'
require 'archive'
require 'writechain'

kind = ARGV[0].to_sym
options = eval(ARGV[1])

bm = BackupManager.new(options)
archive = Archive.new(WriteChain.create(kind,options))

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
