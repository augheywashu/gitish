#!/bin/sh

ruby backup.rb network "`cat remote.options`" $@
