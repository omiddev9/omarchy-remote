#!/usr/bin/bash

STATE_FILE="/tmp/wayvnc-monitor.state"

get_output() {
    # Prefer the real panel (DSI/eDP) over virtual HEADLESS outputs.
    local output
    output=$(hyprctl monitors 2>/dev/null | awk '/^Monitor / && $2 !~ /HEADLESS/ {print $2; exit}')
    [ -n "$output" ] || output=$(hyprctl monitors 2>/dev/null | awk '/^Monitor / {print $2; exit}')
    echo "$output"
}

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

    if pgrep -x wayvnc > /dev/null 2>&1; then
        port=$(ss -Hltnp 2>/dev/null | awk '/wayvnc/ { n = split($4, a, ":"); print a[n]; exit }')
    fi

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

save_monitor_state() {
    local output="$1"
    hyprctl monitors -j 2>/dev/null | jq -r --arg out "$output" '
        .[] | select(.name == $out) |
        "output=\(.name)\nscale=\(.scale)\ntransform=\(.transform)\nx=\(.x)\ny=\(.y)"
    ' > "$STATE_FILE"
}

restore_monitor_state() {
    [ -f "$STATE_FILE" ] || return 0
    # shellcheck disable=SC1090
    . "$STATE_FILE"
    [ -n "$output" ] || return 0
    hyprctl eval "hl.monitor({ output = \"$output\", mode = \"preferred\", position = \"${x}x${y}\", scale = ${scale}, transform = ${transform} })" >/dev/null 2>&1
    rm -f "$STATE_FILE"
}

set_scale_one() {
    local output="$1"
    local x y transform
    x=$(hyprctl monitors -j 2>/dev/null | jq -r --arg out "$output" '.[] | select(.name == $out) | .x')
    y=$(hyprctl monitors -j 2>/dev/null | jq -r --arg out "$output" '.[] | select(.name == $out) | .y')
    transform=$(hyprctl monitors -j 2>/dev/null | jq -r --arg out "$output" '.[] | select(.name == $out) | .transform')
    [ -n "$x" ] || x=0
    [ -n "$y" ] || y=0
    [ -n "$transform" ] || transform=0
    hyprctl eval "hl.monitor({ output = \"$output\", mode = \"preferred\", position = \"${x}x${y}\", scale = 1, transform = ${transform} })" >/dev/null 2>&1
}

case "$1" in
    "start")
        if ! pgrep -x wayvnc > /dev/null; then
            output=$(get_output)
            save_monitor_state "$output"
            set_scale_one "$output"
            wayvnc --output="$output" --max-fps=60 0.0.0.0 "$(get_port)" > /tmp/wayvnc.log 2>&1 &
            echo "started"
        else
            echo "already running"
        fi
        ;;
    "stop")
        pkill -x wayvnc
        restore_monitor_state
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