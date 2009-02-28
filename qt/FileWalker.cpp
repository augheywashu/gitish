#include "FileWalker.h"
#include <QString>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QtDebug>

FileWalker::FileWalker(const Options & /* options */)
{
}

QString FileWalker::walk_directory(const QString &path, FileWalker::Handler &handler)
{
  handler.begin_directory(path);

  QDir dir(path);
  // I hope QDir is smart with this
  QStringList files = dir.entryList(QDir::Files | QDir::Readable, QDir::Name);
  QStringList directories = dir.entryList(QDir::AllDirs, QDir::Name);

  for(int i=0;i<directories.size();++i) {
    const QString &e = directories.at(i);

    QString fullpath = dir.filePath(e);

    if(skipDirectory(e,fullpath))
      continue;

    QString ret = this->walk_directory(fullpath, handler);
    handler.add_directory(e,fullpath,ret);

//    qDebug() << "Looking at directory " << fullpath;
  }


  for(int i=0;i<files.size();++i) {
    const QString &e = files.at(i);

    QString fullpath = dir.filePath(e);

    QFileInfo stat(fullpath);

    if(skipFile(e,fullpath,stat))
      continue;

    handler.process_file(e,fullpath,stat);
  }

  return "";
}

bool FileWalker::skipFile(const QString & /* file */, const QString & /* fullpath */, const QFileInfo & /* stat */)
{
  return false;
}

bool FileWalker::skipDirectory(const QString &e, const QString & /* fullpath */)
{
  if(e == "." || e == "..")
    return true;

  return false;
}
