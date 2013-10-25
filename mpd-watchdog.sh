#!/bin/sh
#
# mpd-watchdog.sh - monitor mpd while playing internet streams
#
# Copyright (C) 2013 Thomas Kemmer <tkemmer@computer.org>
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Based on http://mpd.wikia.com/wiki/Hack:stream-monitor

# uncomment to trace commands
#set -x

# program name
PROGRAM="$(basename "$0")"

# monitoring interval in seconds
INTERVAL=5

# default log level
LOGLEVEL=1

# mpc command
MPC=mpc

# usage information
USAGE=$(cat <<EOF
Usage: $PROGRAM [OPTION]...
Monitor mpd while playing internet streams.

  -i          monitoring interval in seconds [$INTERVAL]
  -v          produce more verbose output
EOF
)

log_error() {
    echo "$PROGRAM:" "$@" >&2
}

log_info() {
    [ $LOGLEVEL -gt 0 ] && echo "$PROGRAM:" "$@" >&2
}

log_debug() {
    [ $LOGLEVEL -gt 1 ] && echo "$PROGRAM:" "$@" >&2
}

mpd_status() {
    $MPC 2>/dev/null | grep '^\[playing\]' 2>/dev/null
}

# parse command line options
while getopts ":i:v" opt; do
    case $opt in
        i)
            INTERVAL=$OPTARG
            ;;
        v)
            LOGLEVEL=$(($LOGLEVEL + 1))
            ;;
        *)
            echo "$USAGE" >&2
            exit 2
            ;;
    esac
done

shift $(($OPTIND - 1))

PREV_STATUS=$(mpd_status)

while sleep $INTERVAL; do
    STATUS=$(mpd_status)

    if [ -n "$STATUS" ]; then
        log_debug "mpd status:" "$STATUS"

        if [ "$PREV_STATUS" = "$STATUS" ]; then
            log_info "restarting mpd"
            $MPC stop && $MPC play || log_error "error restarting mpd"
        fi
    else
        log_debug "mpd not running/playing"
    fi

    PREV_STATUS="$STATUS"
done
