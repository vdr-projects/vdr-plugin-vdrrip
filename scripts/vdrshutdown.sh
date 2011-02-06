#!/bin/sh

#
# This script executes the script $sleephalt in the backgroud
# an gives the control back to vdr
#
# $sleephalt handles the shutdown with or without nvram-wakeup
# and waits until <plugins-dir>/encode.vdrrip is deleted
#
# It is written by herbert attenberger <herbsl@a-land.de>
#

sleephalt="/usr/local/bin/sleephalt.sh"

if [ -x $sleephalt ]
then
  $sleephalt $1 &
else
  echo 
  echo "script $sleephalt not found"
  echo
fi

exit
