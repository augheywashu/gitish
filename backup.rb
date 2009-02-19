require 'backupmanager'
require 'archive'
require 'blobstore'
require 'datastore'

bm = BackupManager.new
archive = Archive.new(BlobStore.create)

begin
  for path in ARGV
    sha = bm.archive_directory(path,archive)
    archive.write_commit(path,sha)
    puts sha
  end
ensure
  bm.close
  archive.close
end
