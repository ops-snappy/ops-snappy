#!/bin/bash

# Syslog settings
LOGSYSLOG="SYSLOG"
LOGCONSOLE="CONSOLE"
LOGLVLDBG="DBG"
LOGLVLINFO="INFO"
SYSLOGDBG="-v${LOGSYSLOG}:${LOGLVLDBG}"
SYSLOGINFO="-v${LOGSYSLOG}:${LOGLVLINFO}"
CONSDBG="-v${LOGCONSOLE}:${LOGLVLDBG}"
CONSINFO="-v${LOGCONSOLE}:${LOGLVLINFO}"
LOGDEFAULT=${CONSINFO}

# Required directories
DBDIR=$SNAP_DATA/var/run/openvswitch
LOGDIR=$SNAP_DATA/var/log/openvswitch
VTEPDBDIR=$SNAP_DATA/var/local/openvswitch
PIDDIR=$DBDIR
CTLDIR=$PIDDIR
BINDIR=$SNAP/usr/bin
SBINDIR=$SNAP/usr/sbin
SCHEMADIR=$SNAP/usr/share/openvswitch
CFGDIR=$SNAP_DATA/etc/openswitch

# Override the default dir locations in ops-openvswitch
export OVS_SYSCONFDIR=$SNAP/etc
export OVS_PKGDATADIR=$SCHEMADIR
export OVS_RUNDIR=$DBDIR
export OVS_LOGDIR=$LOGDIR

# Override the default install_path and data_path in OpenSwitch
export OPENSWITCH_INSTALL_PATH=$SNAP
export OPENSWITCH_DATA_PATH=$SNAP_DATA

# Make sure the directories exist
for i in $DBDIR $VTEPDBDIR $PIDDIR $CTLDIR $CFGDIR ; do
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
$SBINDIR/ovsdb-server --remote=punix:$DBDIR/db.sock --detach --no-chdir --pidfile=$PIDDIR/ovsdb-server.pid --unixctl=$CTLDIR/ovsdb-server.ctl $LOGDEFAULT $DBDIR/ovsdb.db $DBDIR/config.db $DBDIR/dhcp_leases.db

NOT_YET="ops_cfgd ops-arpmgrd ops-intfd"
OPENSWITCH_DAEMONS="ops-sysd ops-tempd ops-fand ops-powerd ops-pmd ops-ledd ops-vland ops-portd"
for i in $OPENSWITCH_DAEMONS ; do
    daemon_loc=$BINDIR
    daemon_args="--detach --no-chdir $CONSDBG --pidfile=$PIDDIR/$i.pid --unixctl=$CTLDIR/$i.ctl"
    case $i in
        ops_cfgd)
            daemon_args="$daemon_args --database=$DBDIR/db.sock"
            ;;
        *)
            ;;
    esac
    $daemon_loc/$i $daemon_args
done
