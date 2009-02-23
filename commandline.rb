require 'archive'
require 'writechain'
require 'yaml'

module CommandLine
  def self.create(argv, printstats = true)
    kind = argv[0].to_sym
    options = YAML.load(File.read(argv[1]))

    archive = Archive.new(WriteChain.create(kind,options))

    argv.shift
    argv.shift

    begin
      for arg in argv
        yield archive,arg,options
      end
    ensure
      archive.close

      if printstats
        STDERR.puts archive.stats.join("\n")
      end
    end
  end
end
