require 'commandline'

pathprefix = ARGV[0]
ARGV.shift

CommandLine.create(ARGV) do |bm,sha|
  bm.verify_tree(sha,"") do |filepath,shas|
    File.open(File.join(pathprefix,filepath),"r") do |f|
      STDERR.puts "Verifying file #{filepath}"
      for sha in shas
        archivedata = bm.read_sha(sha)
        filedata = f.read(archivedata.size)
        if archivedata != filedata
          raise "Found an error in the archive verses on-disk"
        end
      end
      raise "On-disk file seems larger than the stored option" unless f.eof?
    end
  end
end
