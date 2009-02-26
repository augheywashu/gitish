#!/bin/sh

# There should be better tests than this.

export LOG_IO=1

rm -rf log store-test/* store-remote/* store/* cache-test.db shacache-test.db restore/*

method=network
dir=/fileserver/Personal/terri

sha=`ruby backup.rb $method test.yaml $dir`

if [ $? != 0 ]; then
  exit 1
fi

echo "Restoring files..."

ruby restore.rb $method test.yaml $sha

echo "Verifying files..."

ruby verify.rb $sha $method test.yaml $dir
