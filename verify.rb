require 'commandline'
require 'filewalker'
require 'verifyhandler'

treesha = ARGV[0]
ARGV.shift

CommandLine.create(ARGV) do |archive,path,options|
  handler = VerifyHandler.new(path,archive,treesha)
  walker = FileWalker.new(options)

  walker.walk_directory(path,handler)
end
