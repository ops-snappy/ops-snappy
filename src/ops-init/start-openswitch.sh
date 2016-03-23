#!/bin/sh

# Required directories
/usr/bin/test -d $SNAP_DATA/var/run/openvswitch || mkdir -p $SNAP_DATA/var/run/openvswitch
/usr/bin/test -d $SNAP_DATA/var/local/openvswitch || mkdir -p $SNAP_DATA/var/local/openvswitch

# Alphanetworks fan control
if [ -d /sys/class/gpio/gpiochip452 ] ; then
    if [ ! -d /sys/class/gpio/gpio470 ] ; then
        echo '470' | tee --append /sys/class/gpio/export > /dev/null
        echo 'out' | tee --append /sys/class/gpio/gpio470/direction > /dev/null
    fi
    echo '0' | tee --append /sys/class/gpio/gpio470/value > /dev/null
fi

# Init
$SNAP/usr/sbin/ops-init

# OVSDB Server
/usr/bin/test -f $SNAP_DATA/var/run/openvswitch/ovsdb.db || $SNAP/usr/bin/ovsdb-tool create $SNAP_DATA/var/run/opsenvswitch/ovsdb.db $SNAP/usr/share/openvswitch/vswitch.ovsschema
/usr/bin/test -f /var/local/openvswitch/vtep.db || $SNAP/usr/bin/ovsdb-tool create $SNAP_DATA/var/local/openvswitch/vtep.db $SNAP/usr/share/openvswitch/vtep.ovsschema
/usr/bin/test -f $SNAP_DATA/var/local/opsenvswitch/dhcp_leases.db || $SNAP/usr/bin/ovsdb-tool create $SNAP_DATA/var/local/opsenvswitch/dhcp_leases.db $SNAP/usr/share/openvswitch/dhcp_leases.ovsschema
/usr/bin/test -f $SNAP_DATA/var/local/opsenvswitch/config.db || $SNAP/usr/bin/ovsdb-tool create $SNAP_DATA/var/local/opsenvswitch/configdb.db $SNAP/usr/share/openvswitch/configdb.ovsschema
/usr/bin/test -f $SNAP_DATA/var/run/opsenvswitch/ovsdb.db || $SNAP/usr/bin/ovsdb-tool create $SNAP_DATA/var/run/opsenvswitch/ovsdb.db $SNAP/usr/share/openvswitch/vswitch.ovsschema
$SNAP/usr/sbin/ovsdb-server --remote=punix:$SNAP_DATA/var/run/openvswitch/db.sock --detach --no-chdir --pidfile -vSYSLOG:INFO $SNAP_DATA/var/local/opsenvswitch/ovsdb.db $SNAP_DATA/var/local/opsenvswitch/config.db
