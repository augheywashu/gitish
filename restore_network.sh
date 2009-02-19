#!/bin/sh

. ./remote.env

options="{:crypt_key => '$CRYPT_KEY', :remote_command => \"$GITISH_REMOTE\"}"

ruby restore.rb network "$options" $@
