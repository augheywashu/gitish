require 'backupmanager'
require 'archive'
require 'blobstore'
require 'datastore'

bm = BackupManager.new
archive = Archive.new(BlobStore.new(DataStore.new("rawdata")))

begin
  for path in ARGV
    sha = bm.archive_directory(path,archive)
    archive.write_commit(path,sha)
  end
ensure
  bm.close
  archive.close
end
