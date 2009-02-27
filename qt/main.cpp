#include "FileWalker.h"

int main(int argc, char *argv[])
{
  Options options;
  FileWalker walker(options);
  FileWalker::NullHandler handler;

  for(int i=1;i<argc;i++) {
    walker.walk_directory(argv[i],handler);
  }

  return 0;
}
