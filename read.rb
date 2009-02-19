require 'archive'
require 'writechain'

archive = Archive.new(WriteChain.create(ARGV[0].to_sym,eval(ARGV[1])))

ARGV.shift
ARGV.shift

for sha in ARGV
  data = archive.read_sha(sha)
  puts data
end
