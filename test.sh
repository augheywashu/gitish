#!/bin/sh

# There should be better tests than this.

export LOG_IO=1

rm -rf store/* *.db restore/*

options="{:crypt_key => 'jfaiowjioewajg', :remote_command => 'ruby remote.rb'}"
method=network

sha=`ruby backup.rb $method "$options" ../augtion/test`

ruby restore.rb $method "$options" $sha
