#ifndef _ARCHIVE_H
#define _ARCHIVE_H

#include <QString>
#include "Store.h"
#include "options.h"

class QFileInfo;

class Archive {
  public:
    Archive(Store &store, const Options &options);
    QString write_file(const QString &fullpath, const QFileInfo &stat);
  protected:
    Store &m_store;
};

#endif
