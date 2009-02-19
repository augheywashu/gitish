#!/bin/sh

# There should be better tests than this.

export LOG_IO=1
export GITISH_REMOTE='ruby blobstoreremote.rb'
export CRYPT_KEY='jklfdsajlkfdsaijofdsaoi'

rm -rf store/* *.db restore/*

options="{:crypt_key => 'jfaiowjioewajg', :remote_command => 'ruby blobstoreremote.rb'}"

sha=`ruby backup.rb network "$options" ../augtion/test`

ruby restore.rb network "$options" $sha
