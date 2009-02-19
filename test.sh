#!/bin/sh

# There should be better tests than this.

export LOG_IO=1

rm -f store/* *.db

sha=`ruby backup.rb ../augtion/test`

ruby restore.rb $sha
