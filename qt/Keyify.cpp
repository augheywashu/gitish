#include "Keyify.h"
#include "sha1.h"

QString Keyify::write(const QString &, const QByteArray &value) {
  SHA1 sha;
  sha.Input(value.constData(), value.size());

  unsigned      message_digest[5];
  sha.Result(message_digest);

  QString shastr;
  shastr.sprintf("%08X%08X%08X%08X%08X",
      message_digest[0],
      message_digest[1],
      message_digest[2],
      message_digest[3],
      message_digest[4]);

  return m_child.write(shastr,value);
}
