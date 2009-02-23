require 'commandline'

CommandLine.create(ARGV) do |bm,path|
  sha = bm.archive_directory(path)
  bm.archive.write_commit(sha,path + " - " + Time.now.to_s)
  puts sha
end

exit 0
