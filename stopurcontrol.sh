#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PID_FILE="$SCRIPT_DIR/.urcontrol.pid"

if [[ -r "$PID_FILE" ]]; then
    read -r controller_pid <"$PID_FILE" || true
    if [[ "${controller_pid:-}" =~ ^[0-9]+$ ]] && kill -0 "$controller_pid" 2>/dev/null; then
        kill -9 "$controller_pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
fi
