require 'archive'
require 'writechain'

kind = ARGV[0].to_sym
options = YAML.load(File.read(ARGV[1]))

archive = Archive.new(WriteChain.create(kind,options))

ARGV.shift
ARGV.shift

for sha in ARGV
  data = archive.read_sha(sha)
  puts data
end
