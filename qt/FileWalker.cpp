#include "FileWalker.h"
#include <QString>
#include <QDir>
#include <QFile>
#include <QtDebug>

FileWalker::FileWalker(const Options & /* options */)
{
}

void FileWalker::walk_directory(const QString &path, FileWalker::Handler &handler)
{
  handler.begin_directory(path);

  QDir dir(path);
  // I hope QDir is smart with this
  QStringList files = dir.entryList(QDir::Files | QDir::Readable, QDir::Name);
  QStringList directories = dir.entryList(QDir::AllDirs, QDir::Name);

  for(int i=0;i<directories.size();++i) {
    const QString &e = directories.at(i);
    if(e == "." || e == "..")
      continue;

    QString fullpath = dir.filePath(e);

    qDebug() << "Looking at directory " << fullpath;
  }


  for(int i=0;i<files.size();++i) {
    const QString &e = files.at(i);

    QString fullpath = dir.filePath(e);

    qDebug() << "Looking at file " << fullpath;
  }

}
