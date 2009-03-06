#include "StreamStore.h"
#include <QByteArray>

StreamStore::StreamStore(QIODevice &readdevice, QIODevice &writedevice) : m_readdevice(readdevice), m_writedevice(writedevice), m_readtextstream(&readdevice), m_writetextstream(&writedevice)
{
}

QByteArray StreamStore::read(const QString &key)
{
  m_writetextstream << "read " << key << "\n";
  m_writetextstream.flush();
  QString size = m_readtextstream.readLine();
  unsigned int isize = size.toUInt();
  return m_readdevice.read(isize);
}

QString StreamStore::write(const QString &key, const QByteArray &value)
{
  m_writetextstream << "write " << key << " " << value.size() << "\n";
  m_writetextstream.flush();
  m_writedevice.write(value);
  QString ret = m_readtextstream.readLine();
  if(ret != key) {
    abort();
  }
  return ret;
}

bool StreamStore::has_key(const QString &key, bool )
{
  m_writetextstream << "sha? " << key << "\n";
  m_writetextstream.flush();
  QString ret = m_readtextstream.readLine();
  if(ret == "1")
    return true;
  else
    return false;
}

void StreamStore::sync()
{
  m_writetextstream << "sync\n";
  m_writetextstream.flush();
}
