#!/bin/sh

# There should be better tests than this.

export LOG_IO=1

rm -rf log store-test/* store/* cache-test.db shacache-test.db restore/*

method=network

sha=`ruby backup.rb $method test.yaml /fileserver/Personal/terri`

if [ $? != 0 ]; then
  exit 1
fi

echo "Restoring files..."

ruby restore.rb $method test.yaml $sha
