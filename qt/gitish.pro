TEMPLATE = app
LANGUAGE = C++
QT -= gui
CONFIG += debug

INCLUDEPATH += /usr/local/include/QtCrypto
LIBS += -lqca

SOURCES = main.cpp FileWalker.cpp BackupHandler.cpp Archive.cpp StreamStore.cpp Keyify.cpp
SOURCES += sha1.cpp
HEADERS = FileWalker.h BackupHandler.h Store.h WriteChain.h Archive.h StreamStore.h Keyify.h
SOURCES += sha1.h
