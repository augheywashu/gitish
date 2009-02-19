#!/bin/sh

# There should be better tests than this.

export LOG_IO=1
export GITISH_REMOTE='ruby blobstoreremote.rb'
export CRYPT_KEY='jklfdsajlkfdsaijofdsaoi'

rm -rf store/* *.db restore/*

sha=`ruby backup.rb ../augtion/test`

ruby restore.rb $sha
