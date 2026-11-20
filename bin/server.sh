#!/usr/bin/bash

get_ip() {
    ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1
}

case "$1" in
    "start")
        if ! pgrep -x wayvnc > /dev/null; then
            wayvnc 0.0.0.0 > /tmp/wayvnc.log 2>&1 &
            echo "started"
        else
            echo "already running"
        fi
        ;;
    "stop")
        pkill -x wayvnc
        echo "stopped"
        ;;
    "status")
        if pgrep -x wayvnc > /dev/null; then
            echo "running"
        else
            echo "stopped"
        fi
        ;;
    "ip")
        get_ip
        ;;
esac
