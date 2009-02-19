#!/bin/sh

ruby restore.rb local "`cat local.options`" $@
