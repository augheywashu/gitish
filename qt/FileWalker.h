#ifndef _FILEWALKER_H
#define _FILEWALKER_H

#include "options.h"
#include <QString>
#include <QStringList>

class QFileInfo;

class FileWalker {
  public:
    class Handler {
      public:
        virtual ~Handler() { }
        virtual void begin_directory(const QString &path) = 0;
        virtual void add_directory(const QString &name, const QString &fullpath, const QString &key) = 0;
        virtual void process_file(const QString &name, const QString &fullpath, const QFileInfo &stat) = 0;
    };

    class NullHandler : public Handler {
      public:
        virtual ~NullHandler() { }
        virtual void begin_directory(const QString &) { }
        virtual void add_directory(const QString &, const QString &, const QString &) { }
        virtual void process_file(const QString &, const QString &, const QFileInfo &) { }
    };

    FileWalker(const Options &options);
    QString walk_directory(const QString &path, Handler &handler);
  protected:
    bool skipFile(const QString &file, const QString &fullpath, const QFileInfo &);
    bool skipDirectory(const QString &file, const QString &fullpath);

    QStringList m_ignoredFiles;
};

#endif
