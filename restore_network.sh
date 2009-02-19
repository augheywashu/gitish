#!/bin/sh

ruby restore.rb network "`cat remote.options`" $@
