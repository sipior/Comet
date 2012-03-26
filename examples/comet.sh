#! /bin/sh
### BEGIN INIT INFO
# Provides:          comet
# Required-Start:    $syslog
# Required-Stop:     $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

# Author: John Swinbank <swinbank@transientskp.org>

set -e

PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="Comet VOEvent Broker"
NAME=comet
DAEMON=/usr/bin/twistd
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME
LOGFILE=/var/log/comet/comet.log
IVORNDB=/var/run/comet
DAEMON_ARGS="--pidfile ${PIDFILE} --logfile ${LOGFILE} comet -b --ivorndb ${IVORNDB}"

# Site specific configuration
LOCAL_IVORN="ivo://comet.broker/default_ivo"
REMOTES="--remote voevent.voevent.transientskp.org"

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

do_start()
{
    # Return
    #   0 if daemon has been started
    #   1 if daemon was already running
    #   2 if daemon could not be started

    # Exit if we don't have a local ivorn
    [ $LOCAL_IVORN ]  || return 2

    # Create directory for log file and ivorn database
    mkdir -p `dirname $LOGFILE` || return 2
    mkdir -p $IVORNDB || return 2

    start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON --test > /dev/null \
        || return 1
    start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- \
        $DAEMON_ARGS --local-ivo ${LOCAL_IVORN} ${REMOTES}\
        || return 2
}

do_stop()
{
    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE
    return "$?"
}

case "$1" in
  start)
    do_start
    case "$?" in
        0|1) exit 0 ;; # Started (or already running)
        2)   exit 1 ;; # Failed to start
    esac
    ;;
  stop)
    do_stop
    case "$?" in
        0|1) exit 0 ;;
        2)   exit 1 ;;
    esac
    ;;
  restart|force-reload)
    do_stop
    case "$?" in
      0|1)
        do_start
        case "$?" in
            0) exit 0 ;;
            1) exit 1 ;; # Old process is still running
            *) exit 1 ;; # Failed to start
        esac
        ;;
      *)
        # Failed to stop
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
    exit 3
    ;;
esac
