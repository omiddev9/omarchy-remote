#!/usr/bin/bash

get_ip() {
    local addr
    addr=$(ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | grep -v '^127\.' | head -n1)
    [ -n "$addr" ] || addr=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "src") { print $(i + 1); exit }}')
    case "$addr" in
        ""|0.0.0.0|127.*) ;;
        *) echo "$addr" ;;
    esac
}

get_port() {
    local port=""
    local cfg

    # Prefer the port the running instance actually listens on.
    if pgrep -x wayvnc > /dev/null 2>&1; then
        port=$(ss -Hltnp 2>/dev/null | awk '/wayvnc/ { n = split($4, a, ":"); print a[n]; exit }')
    fi

    # Otherwise read the configured port, then fall back to wayvnc's default.
    if [ -z "$port" ]; then
        cfg="${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc/config"
        [ -f "$cfg" ] || cfg=/etc/wayvnc/config
        if [ -f "$cfg" ]; then
            port=$(sed -n 's/^[[:space:]]*port[[:space:]]*=[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$cfg" | tail -n1)
        fi
    fi

    case "$port" in
        ""|*[!0-9]*) port=5900 ;;
    esac
    echo "$port"
}

case "$1" in
    "start")
        if ! pgrep -x wayvnc > /dev/null; then
            # Low-latency setup for LAN: high FPS, let the client draw the cursor
            # (faster than burning it into the framebuffer), single output.
            wayvnc --max-fps=60 0.0.0.0 "$(get_port)" > /tmp/wayvnc.log 2>&1 &
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
    "port")
        get_port
        ;;
esac