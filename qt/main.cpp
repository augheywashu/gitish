#include "FileWalker.h"
#include "BackupHandler.h"
#include "Store.h"
#include "StreamStore.h"
#include <QFile>
#include "Keyify.h"

int main(int argc, char *argv[])
{
  Options options;
  const Options &coptions = options;

  QFile qstdin;
  qstdin.open(stdin, QIODevice::ReadOnly);
  QFile qstdout;
  qstdout.open(stdout, QIODevice::WriteOnly);

  StreamStore ss(qstdin,qstdout);
  Keyify keyify(ss);
  Archive archive(keyify,coptions);
  BackupHandler handler(archive,coptions);

  FileWalker walker(coptions);

  for(int i=1;i<argc;i++) {
    walker.walk_directory(argv[i],handler);
  }

  return 0;
}
