require 'backupmanager'
require 'archive'
require 'blobstore'
require 'datastore'
require 'blobstorelocal'

bm = BackupManager.new
#archive = Archive.new(BlobStore.new(DataStore.new("rawdata")))
archive = Archive.new(BlobStoreLocal.new("ruby blobstoreremote.rb"))

begin
  for path in ARGV
    sha = bm.archive_directory(path,archive)
    archive.write_commit(path,sha)
  end
ensure
  bm.close
  archive.close
end
