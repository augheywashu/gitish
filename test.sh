#!/bin/sh

# There should be better tests than this.

export LOG_IO=1

rm -rf store-test/* store/* *.db restore/*

options="{:crypt_key => 'jfaiowjioewajg', :remote_command => 'ruby remote.rb', :storedir => 'store-test'}"
method=local

sha=`ruby backup.rb $method "$options" /fileserver/Personal/terri`

ruby restore.rb $method "$options" $sha
