#ifndef _STORE_H
#define _STORE_H

#include <QString>
#include <QByteArray>

class Store {
  public:
    virtual ~Store() { }
    virtual QByteArray read(const QString &key) = 0;
    virtual QString write(const QString &key, const QByteArray &value) = 0;
    virtual bool has_key(const QString &key, bool skip_cache) = 0;
    virtual void sync() { }

    inline QString write(const QString &key, const QString &value) {
      return this->write(key,value.toAscii());
    }
};

class NullStore : public Store {
  public:
    virtual ~NullStore() { }
    virtual QByteArray read(const QString &) { return QByteArray(); }
    virtual QString write(const QString &key, const QByteArray &) { return key; }
    virtual bool has_key(const QString &, bool ) { return false; }
};

#endif
