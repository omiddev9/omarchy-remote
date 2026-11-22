#!/usr/bin/bash

STATE_FILE="/tmp/wayvnc-monitor.state"

get_source_output() {
    # Prefer the real panel (DSI/eDP) over virtual HEADLESS outputs.
    local output
    output=$(hyprctl monitors 2>/dev/null | awk '/^Monitor / && $2 !~ /HEADLESS/ {print $2; exit}')
    [ -n "$output" ] || output=$(hyprctl monitors 2>/dev/null | awk '/^Monitor / {print $2; exit}')
    echo "$output"
}

create_mirror_output() {
    local src="$1"
    local before after name
    before=$(hyprctl monitors all -j 2>/dev/null | jq -r '.[].name' | grep '^HEADLESS-' | sort)
    hyprctl output create headless >/dev/null 2>&1
    sleep 0.5
    after=$(hyprctl monitors all -j 2>/dev/null | jq -r '.[].name' | grep '^HEADLESS-' | sort)
    name=$(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | head -n1)
    [ -n "$name" ] || name=$(hyprctl monitors all -j 2>/dev/null | jq -r '.[] | select(.mirrorOf != "none") | .name' | tail -n1)
    [ -n "$name" ] || return 1
    hyprctl eval "hl.monitor({ output = \"$name\", mode = \"preferred\", position = \"0x0\", scale = 1, transform = 0, mirror = \"$src\" })" >/dev/null 2>&1
    sleep 0.3
    printf '%s\n' "$name"
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

cleanup_mirror() {
    if [ -f "$STATE_FILE" ]; then
        # shellcheck disable=SC1090
        . "$STATE_FILE"
        if [ -n "${mirror_output:-}" ]; then
            hyprctl output remove "$mirror_output" >/dev/null 2>&1
        fi
        rm -f "$STATE_FILE"
    fi
}

case "$1" in
    "start")
        if ! pgrep -x wayvnc > /dev/null; then
            src=$(get_source_output)
            mirror=$(create_mirror_output "$src")
            if [ -n "$mirror" ]; then
                printf 'mirror_output=%s\nsource=%s\n' "$mirror" "$src" > "$STATE_FILE"
                target="$mirror"
            else
                target="$src"
            fi
            wayvnc --output="$target" --max-fps=60 0.0.0.0 "$(get_port)" > /tmp/wayvnc.log 2>&1 &
            echo "started"
        else
            echo "already running"
        fi
        ;;
    "stop")
        pkill -x wayvnc
        cleanup_mirror
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