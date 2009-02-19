#!/bin/sh

ruby backup.rb local "`cat local.options`" $@
