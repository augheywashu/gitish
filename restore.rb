require 'fileutils'
require 'archive'
require 'blobstore'
require 'datastore'


def restore_dir(sha,archive,path)
  puts "Restoring directory #{path}"
  FileUtils.mkdir_p(path)

  dirs,files = archive.read_directory(sha)
  for dirname,sha in dirs
    restore_dir(sha,archive,File.join(path,dirname))
  end
  for filename,shas in files
    fullpath = File.join(path,filename)
    puts "Restoring file #{fullpath}"
    shas = "" unless shas
    File.open(fullpath,"w") do |f|
      for sha in shas.split(',')
        f.write(archive.read_sha(sha))
      end
    end
  end
end

archive = Archive.new(BlobStore.new(DataStore.new("rawdata")))

begin
  restore_dir(ARGV[0],archive,"restore")
ensure
  archive.close
end
