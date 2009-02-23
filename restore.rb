require 'commandline'

CommandLine.create(ARGV) do |bm,sha|
  bm.restore_dir(sha,"restore")
end

exit 0
