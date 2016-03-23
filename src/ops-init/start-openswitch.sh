#!/bin/sh

# Required directories
DBDIR=$SNAP_DATA/var/run/openvswitch
VTEPDBDIR=$SNAP_DATA/var/local/openvswitch
PIDDIR=$DBDIR
CTLDIR=$PIDDIR
BINDIR=$SNAP/usr/bin
SBINDIR=$SNAP/usr/sbin
SCHEMADIR=$SNAP/usr/share/openvswitch

for i in $DBDIR $VTEPDBDIR $PIDDIR $CTLDIR ; do
    /usr/bin/test -d $i || mkdir -p $i
done

# Alphanetworks software fan control
if [ -d /sys/class/gpio/gpiochip452 ] ; then
    if [ ! -d /sys/class/gpio/gpio470 ] ; then
        echo '470' | tee --append /sys/class/gpio/export > /dev/null
        echo 'out' | tee --append /sys/class/gpio/gpio470/direction > /dev/null
    fi
    echo '0' | tee --append /sys/class/gpio/gpio470/value > /dev/null
fi

# Create the network namespaces
$SBINDIR/ops-init

# Create the databases if they don't exist.
/usr/bin/test -f $DBDIR/ovsdb.db || $BINDIR/ovsdb-tool create $DBDIR/ovsdb.db $SCHEMADIR/vswitch.ovsschema
/usr/bin/test -f $VTEPDBDIR/vtep.db || $BINDIR/ovsdb-tool create $VTEPDBDIR/vtep.db $SCHEMADIR/vtep.ovsschema
/usr/bin/test -f $DBDIR/dhcp_leases.db || $BINDIR/ovsdb-tool create $DBDIR/dhcp_leases.db $SCHEMADIR/dhcp_leases.ovsschema
/usr/bin/test -f $DBDIR/config.db || $BINDIR/ovsdb-tool create $DBDIR/config.db $SCHEMADIR/configdb.ovsschema
/usr/bin/test -f $DBDIR/ovsdb.db || $BINDIR/ovsdb-tool create $DBDIR/ovsdb.db $SCHEMADIR/vswitch.ovsschema

# OVSDB Server
# TODO - By default, the unix control socket is located at
#        /var/run/openvswitch/<name>.<pid>.ctl.  Can't dynamically
#        assign the assign the pid if we are specifying a non-default
#        location for the pid.
$SBINDIR/ovsdb-server --remote=punix:$DBDIR/db.sock --detach --no-chdir --pidfile=$PIDDIR/ovsdb-server.pid --unixctl=$CTLDIR/ovsdb-server.ctl -vSYSLOG:INFO $DBDIR/ovsdb.db $DBDIR/config.db $DBDIR/dhcp_leases.db
