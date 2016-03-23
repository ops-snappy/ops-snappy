#!/bin/sh

# Required directories
DBDIR=$SNAP_DATA/var/run/openvswitch
VTEPDBDIR=$SNAP_DATA/var/local/openvswitch
PIDDIR=$DBDIR
CTLDIR=$PIDDIR
DBSVR="ovsdb-server.pid"

for i in $PIDDIR/*.pid ; do
    pid=`cat $i`
    if [ -z "${i##*$DBSVR}" ] ; then
        dbsvrpid=$pid
    else
        kill -9 $pid
    fi
done

if [ -d /sys/class/gpio/gpiochip452 ] ; then
    if [ -d /sys/class/gpio/gpio470 ] ; then
        echo '1' | tee --append /sys/class/gpio/gpio470/value > /dev/null
        echo '470' | tee --append /sys/class/gpio/unexport > /dev/null
    fi
fi

if [ ! -z "$dbsvrpid" ] ; then
    sleep 1
    kill -9 $dbsvrpid
fi

rm -f  $PIDDIR/*.pid
rm -f  $CTLDIR/*.ctl
