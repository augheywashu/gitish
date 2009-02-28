#include "FileWalker.h"
#include "BackupHandler.h"
#include "Store.h"

int main(int argc, char *argv[])
{
  Options options;
  const Options &coptions = options;

  FileWalker walker(coptions);
  NullStore store;
  Archive archive(store,coptions);
  BackupHandler handler(archive,coptions);

  for(int i=1;i<argc;i++) {
    walker.walk_directory(argv[i],handler);
  }

  return 0;
}
