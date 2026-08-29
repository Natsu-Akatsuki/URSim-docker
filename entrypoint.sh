#!/usr/bin/env bash
set -Eeuo pipefail

log() {
    printf '[ursim] %s\n' "$*" >&2
}

configure_gpu() {
    export NVIDIA_VISIBLE_DEVICES="${NVIDIA_VISIBLE_DEVICES:-all}"
    export NVIDIA_DRIVER_CAPABILITIES="${NVIDIA_DRIVER_CAPABILITIES:-graphics,display,utility}"
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    log "GPU: NVIDIA"
}

start_ursim() {
    local robot_type="${1:-${ROBOT_TYPE:-UR5}}"

    case "$robot_type" in
        UR3|UR5|UR7e|UR8LONG|UR10|UR12e|UR15|UR16|UR18|UR20|UR30) ;;
        *)
            log "不支持的机器人型号: ${robot_type}"
            log "可选: UR3 UR5 UR7e UR8LONG UR10 UR12e UR15 UR16 UR18 UR20 UR30"
            exit 64
            ;;
    esac

    if [[ -z "${DISPLAY:-}" ]]; then
        log 'DISPLAY 未设置；请挂载 /tmp/.X11-unix 并传入宿主机 DISPLAY。'
        exit 69
    fi

    configure_gpu

    if command -v glxinfo >/dev/null 2>&1; then
        local renderer
        renderer="$(glxinfo -B 2>/dev/null | awk -F': ' '/OpenGL renderer string/ {print $2; exit}')"
        [[ -n "$renderer" ]] && log "OpenGL renderer: ${renderer}"
    fi

    log "启动 URSim ${robot_type}，DISPLAY=${DISPLAY}"
    exec /opt/ursim/start-ursim.sh "$robot_type"
}

case "${1:-}" in
    UR3|UR5|UR7e|UR8LONG|UR10|UR12e|UR15|UR16|UR18|UR20|UR30)
        start_ursim "$1"
        ;;
    ursim)
        shift
        start_ursim "${1:-${ROBOT_TYPE:-UR5}}"
        ;;
    '')
        start_ursim "${ROBOT_TYPE:-UR5}"
        ;;
    *)
        exec "$@"
        ;;
esac
