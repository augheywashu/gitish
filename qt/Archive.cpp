#include "Archive.h"
#include <QFileInfo>
#include <QStringList>
#include <QtDebug>

Archive::Archive(Store &store, const Options &) : m_store(store)
{
}

QString Archive::write_file(const QString &fullpath, const QFileInfo &stat)
{
  const int CHUNKSIZE = 1048576;

  qDebug() << "Archive: writing " << fullpath;

  QStringList shas;

  QFile file(fullpath);
  if(file.open(QFile::ReadOnly) == false) {
    qDebug() << "Could not access " << fullpath << ".  Not backed up.";
    return "";
  }

  unsigned int numchunks = (unsigned int)(stat.size() / (double)CHUNKSIZE + 0.5);
  unsigned int bytesread = 0;
  unsigned int chunk = 0;
  unsigned int chunkmod = numchunks / 4;

  while(! file.atEnd()) {
    QByteArray data = file.read(CHUNKSIZE);

    if(data.size == 0)
      break;

    bytesread += data.size();

    if(numchunks > 4 && chunk % chunkmod == 0) {
      qDebug() << "Writing chunk " << chunk + 1 << " of " << numchunks;
    }
    QString sha = m_store.write("",data);
    shas << sha;
    chunk += 1;
  }

  file.close();

  if(bytesread != stat.size()) {
    qDebug() << "Short Read.  Expected to read " << stat.size() << ", actually read " << bytesread;
    return ""; // XX Should indicate this error
  }

  if(shas.size() == 1) {
    return shas[0];
  } else {
    QString filesha = m_store.write("", shas.join("\n"));
    return QString("*") + m_store.write("", filesha);
  }
}
