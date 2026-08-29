# URSim Docker

本项目通过宿主机 X11 直连显示 PolyScope，解决 UR 官方 Docker 镜像（基于 noVNC ）渲染慢的问题。

## 支持的机器人型号

`UR3`、`UR5`、`UR7e`、`UR8LONG`、`UR10`、`UR12e`、`UR15`、`UR16`、`UR18`、`UR20`、`UR30`。

## 环境要求

- NVIDIA GPU

- X11 宿主机
- Docker
- NVIDIA Container Toolkit。

## 启动方式（二选一）

### 方式 1：使用 `run.sh`

首次使用或需要重新编译镜像时，加上 `BUILD=1`：

```bash
chmod +x run.sh
BUILD=1 ./run.sh UR7e
```

镜像已经编译后，可以直接启动：

```bash
./run.sh UR7e
```

`run.sh` 会自动创建 Docker bridge 网络、复制当前 X11 display cookie、挂载 X11 socket，并请求 NVIDIA GPU。若没有 `xauth`，脚本会临时执行 `xhost +SI:localuser:root`，退出时撤销授权。

### 方式 2：使用 Docker Compose

> [!NOTE]
>
> Compose 需要将 X11 cookie 文件挂载到容器中；如需自动生成只包含当前 display cookie 的临时文件，可以使用 `run.sh` 方式。

1. 首次使用 Compose 前创建网络：

```bash
docker network create --driver bridge --subnet 192.168.56.0/24 ursim_net
```

2. 然后启动：

```bash
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
docker compose up --build
```

如果显示管理器没有使用 `$HOME/.Xauthority`，可用 `xauth info` 查看当前 Authority file。

### RTDE 连接示例

RTDE 客户端应连接容器地址和容器端口：

```python
ROBOT_IP = "192.168.56.101"
rtde_r = rtde_receive.RTDEReceiveInterface(ROBOT_IP)
rtde_c = rtde_control.RTDEControlInterface(ROBOT_IP)
```
