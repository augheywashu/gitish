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

class StoreChain : public Store {
  public:
    StoreChain(Store &child) : m_child(child) { }
    virtual ~StoreChain() { }

    virtual QByteArray read(const QString &key) {
      return m_child.read(key);
    }

    virtual QString write(const QString &key, const QByteArray &value) {
      return m_child.write(key,value);
    }

    virtual bool has_key(const QString &key, bool skip_cache) {
      return m_child.has_key(key, skip_cache);
    }

    virtual void sync() { 
      m_child.sync();
    }
  protected:
    Store &m_child;
};

class NullStore : public Store {
  public:
    virtual ~NullStore() { }
    virtual QByteArray read(const QString &) { return QByteArray(); }
    virtual QString write(const QString &key, const QByteArray &) { return key; }
    virtual bool has_key(const QString &, bool ) { return false; }
};

#endif
