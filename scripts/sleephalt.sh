#!/bin/sh

#
# This script is called by vdrshutdown.sh
#
# It is written by herbert attenberger <herbsl@a-land.de>
#

#
# initial definitions
#

pgrep="/usr/bin/pgrep"
nvramwakeup="/usr/local/bin/nvram-wakeup"
netcat="/usr/bin/netcat"

pluginsdir="/etc/vdrtmpfs/plugins"

scriptname=`basename $0`

# reboot needed for nvram-wakeup (yes/no) ?
nvramreboot="yes"


vdrecho () {
#
# echo $1 in the vdr-infobar (or console)
#

if [ -x "$netcat" ]
then
  echo "MESG $1" | $netcat -q 1 localhost 2001
else
  echo $1
fi
 
}

#
# this is the main part
#

if [ -e "$pluginsdir/encode.vdrrip" ]
then
  # check, if there is already an active shutdown-procedure:
  pids=`"$pgrep" -d" " "$scriptname"`
  pid1=`echo "$pids" | cut -d" " -f1`
  pid2=`echo "$pids" | cut -d" " -f3`

  if [ "$pid1" != "$pid2" ]
  then
    vdrecho "a shutdown-procedure is already active"
    exit 
  else
    vdrecho "shutdown after vdrrip-encoding is finished" 
    while [ -e "$pluginsdir/encode.vdrrip" ]
    do
      sleep 60
    done

    # shutdown vdr with the power-key and exit the script
    echo "HITK Power" | $netcat -q 1 localhost 2001
    exit
  fi
else
  if [ -x "$nvramwakeup" -a "$1" != "0" ]
  then
    if [ "$nvramreboot" = "yes" ]
    then
      # shutdown with reboot
      $nvramwakeup -ls $1
      lilo -R PowerOff
      reboot
    else
      # shutdown without reboot
      $nvramwakeup -ls $1
      halt
    fi
  else
    # shutdown without nvram-wakeup
    halt
  fi
fi
