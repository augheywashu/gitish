#!/bin/sh

# There should be better tests than this.

export LOG_IO=1
export GITISH_REMOTE='ruby remote.rb'
export CRYPT_KEY='jklfdsajlkfdsaijofdsaoi'

rm -rf store/* *.db restore/*

options="{:crypt_key => 'jfaiowjioewajg', :remote_command => 'ruby blobstoreremote.rb'}"
method=network

sha=`ruby backup.rb $method "$options" ../augtion/test`

ruby restore.rb $method "$options" $sha
