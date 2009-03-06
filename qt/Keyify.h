#ifndef _KEYIFY_H
#define _KEYIFY_H

#include "Store.h"

class Keyify : public StoreChain {
  public:
    Keyify(Store &child) : StoreChain(child) { }
    virtual QString write(const QString &key, const QByteArray &value);
};

#endif
