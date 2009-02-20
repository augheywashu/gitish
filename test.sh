#!/bin/sh

# There should be better tests than this.

export LOG_IO=1

rm -rf store-test/* store/* cache-test.db restore/*

method=local

sha=`ruby backup.rb $method test.yaml /fileserver/Personal/terri`

ruby restore.rb $method test.yaml $sha
