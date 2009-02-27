#ifndef _FILEWALKER_H
#define _FILEWALKER_H

#include "options.h"
#include <QString>
#include <QStringList>

class FileWalker {
  public:
    class Handler {
      public:
        virtual ~Handler() { }
        virtual void begin_directory(const QString &path) = 0;
    };

    class NullHandler : public Handler {
      public:
        virtual ~NullHandler() { }
        virtual void begin_directory(const QString &) { }
    };

    FileWalker(const Options &options);
    void walk_directory(const QString &path, Handler &handler);
  protected:
    QStringList m_ignoredFiles;
};

#endif
