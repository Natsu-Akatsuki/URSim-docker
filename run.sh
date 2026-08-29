#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE="${URSIM_IMAGE:-ursim:5.26.0}"
ROBOT_TYPE="${1:-${ROBOT_TYPE:-UR5}}"
NETWORK_NAME="ursim_net"
ROBOT_IP="192.168.56.101"
XHOST_GRANTED=0
XAUTH_FILE=''

usage() {
    cat <<'EOF'
用法: ./run.sh [UR3|UR5|UR7e|UR8LONG|UR10|UR12e|UR15|UR16|UR18|UR20|UR30]

环境变量:
  URSIM_IMAGE=名称:标签                 镜像名称，默认 ursim:5.26.0
  BUILD=1                              执行 docker build
EOF
}

cleanup() {
    if (( XHOST_GRANTED )); then
        xhost -SI:localuser:root >/dev/null 2>&1 || true
    fi
    if [[ -n "$XAUTH_FILE" && -f "$XAUTH_FILE" ]]; then
        rm -f -- "$XAUTH_FILE"
    fi
}
trap cleanup EXIT

case "$ROBOT_TYPE" in
    -h|--help) usage; exit 0 ;;
    UR3|UR5|UR7e|UR8LONG|UR10|UR12e|UR15|UR16|UR18|UR20|UR30) ;;
    *) printf '不支持的机器人型号: %s\n' "$ROBOT_TYPE" >&2; usage >&2; exit 64 ;;
esac

if [[ -z "${DISPLAY:-}" ]]; then
    printf 'DISPLAY 未设置；请从 Linux X11 桌面运行。\n' >&2
    exit 69
fi

if ! command -v nvidia-smi >/dev/null 2>&1 || ! nvidia-smi -L >/dev/null 2>&1; then
    printf '未检测到可用的 NVIDIA GPU/NVIDIA Container Toolkit。此镜像仅支持 NVIDIA。\n' >&2
    exit 69
fi

if [[ "${BUILD:-0}" == 1 ]]; then
    docker build --pull --tag "$IMAGE" .
fi

if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    docker network create \
        --driver bridge \
        --subnet 192.168.56.0/24 \
        "$NETWORK_NAME" >/dev/null
fi

docker_args=(
    run --rm
    --name "ursim-${ROBOT_TYPE,,}"
    --hostname ursim
    --network "$NETWORK_NAME"
    --ip "$ROBOT_IP"
    --ipc host
    --volume /tmp/.X11-unix:/tmp/.X11-unix:rw
    --env "DISPLAY=$DISPLAY"
    --env NVIDIA_VISIBLE_DEVICES=all
    --env NVIDIA_DRIVER_CAPABILITIES=graphics,display,utility
    --env __NV_PRIME_RENDER_OFFLOAD=1
    --env __GLX_VENDOR_LIBRARY_NAME=nvidia
    --env __VK_LAYER_NV_optimus=NVIDIA_only
    --gpus all
)


if [[ -t 0 && -t 1 ]]; then
    docker_args+=(--interactive --tty)
fi

# 为容器复制当前 display 的 cookie；若宿主机没有 xauth，则只授权本地 root。
if command -v xauth >/dev/null 2>&1 && xauth nlist "$DISPLAY" 2>/dev/null | grep -q .; then
    XAUTH_FILE="$(mktemp /tmp/ursim-xauth.XXXXXX)"
    xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f "$XAUTH_FILE" nmerge -
    chmod 0600 "$XAUTH_FILE"
    docker_args+=(--volume "$XAUTH_FILE:/tmp/.docker.xauth:ro" --env XAUTHORITY=/tmp/.docker.xauth)
else
    command -v xhost >/dev/null 2>&1 || {
        printf '需要宿主机安装 xauth 或 xhost 才能授权 X11。\n' >&2
        exit 69
    }
    xhost +SI:localuser:root >/dev/null
    XHOST_GRANTED=1
fi

docker "${docker_args[@]}" "$IMAGE" "$ROBOT_TYPE"
