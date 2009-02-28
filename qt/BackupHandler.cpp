#include "BackupHandler.h"

BackupHandler::BackupHandler(Archive &archive, const Options &options) : m_archive(archive)
{
}

void BackupHandler::begin_directory(const QString &path)
{
}

void BackupHandler::add_directory(const QString &name, const QString &fullpath, const QString &key)
{
}

void BackupHandler::process_file(const QString &name, const QString &fullpath, const QFileInfo &stat)
{
  QString key = m_archive.write_file(fullpath,stat);
}
