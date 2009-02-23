require 'backupmanager'
require 'archive'
require 'writechain'

kind = ARGV[0].to_sym
options = YAML.load(File.read(ARGV[1]))

bm = BackupManager.new(options)
archive = Archive.new(WriteChain.create(kind,options))

ARGV.shift
ARGV.shift

begin
  for sha in ARGV
    bm.restore_dir(sha,archive,"restore")
  end
ensure
  archive.close
end
