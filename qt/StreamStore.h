#ifndef _STREAM_STORE_H
#define _STREAM_STORE_H

#include "Store.h"
#include <QIODevice>
#include <QTextStream>
#include <QFile>

class StreamStore : public Store {
  public:
    StreamStore(QIODevice &readdevice, QIODevice &writedevice);
    virtual ~StreamStore() { }
    virtual QByteArray read(const QString &key);
    virtual QString write(const QString &key, const QByteArray &value);
    virtual bool has_key(const QString &key, bool skip_cache);
    virtual void sync();
  protected:
    QIODevice &m_readdevice, &m_writedevice;
    QTextStream m_readtextstream, m_writetextstream;
};

#endif
