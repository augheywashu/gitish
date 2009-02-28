#ifndef _BACKUP_HANDLER_H
#define _BACKUP_HANDLER_H

#include "FileWalker.h"
#include "Archive.h"

class BackupHandler : public FileWalker::Handler {
  public:
    virtual ~BackupHandler() { }
    BackupHandler(Archive &archive, const Options &options);

    virtual void begin_directory(const QString &path);
    virtual void add_directory(const QString &name, const QString &fullpath, const QString &key);
    virtual void process_file(const QString &name, const QString &fullpath, const QFileInfo &stat);
  protected:
    Archive &m_archive;
};

#endif
