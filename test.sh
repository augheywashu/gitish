#!/bin/sh

# There should be better tests than this.

export LOG_IO=1

rm -rf store-test/* store/* cache-test.db shacache-test.db restore/*

method=local

sha=`ruby backup.rb $method test.yaml /fileserver/Personal/terri`

if [ $? != 0 ]; then
  exit 1
fi

ruby restore.rb $method test.yaml $sha
