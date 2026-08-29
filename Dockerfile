# syntax=docker/dockerfile:1
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH
ARG URSIM_VERSION=5.26.0.140464
ARG URSIM_URL=https://s3-eu-west-1.amazonaws.com/ur-support-site/282890/URSim_Linux-5.26.0.140464.tar.gz
ARG URSIM_SHA256=e0b49a3dd3bd8d2bff3849ac524f69562716eb9118073a960a6bae5a83e94671

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    URSIM_HOME=/opt/ursim \
    ROBOT_TYPE=UR5 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=graphics,display,utility

RUN case "${TARGETARCH:-amd64}" in amd64) ;; *) echo "URSim Linux supports amd64 only" >&2; exit 1 ;; esac \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        default-jre \
        fonts-arphic-ukai \
        fonts-arphic-uming \
        fonts-baekmuk \
        fonts-dejavu \
        fonts-ipafont \
        fonts-nanum \
        iproute2 \
        libegl1 \
        libgl1 \
        libglx0 \
        libjava3d-java \
        libjava3d-jni \
        libxcursor1 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxtst6 \
        net-tools \
        openssl \
        procps \
        psmisc \
        tini \
        unzip \
        xauth \
    && curl -fL --retry 5 --connect-timeout 30 "${URSIM_URL}" -o /tmp/ursim.tar.gz \
    && echo "${URSIM_SHA256}  /tmp/ursim.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/ursim \
    && tar -xzf /tmp/ursim.tar.gz --strip-components=2 -C /opt/ursim \
    && test -x /opt/ursim/start-ursim.sh \
    && test -x /opt/ursim/URControl \
    && unzip -q /opt/ursim/GUI/bundle/jogamp-fat-2.3.2-modified.jar \
        'natives/linux-amd64/*' -d /opt/ursim/GUI \
    && test -r /opt/ursim/GUI/natives/linux-amd64/libgluegen-rt.so \
    && keytool -importcert -cacerts -storepass changeit -noprompt \
        -alias ur_robot_root_certificate \
        -file /opt/ursim/.certificate/URRobotRoot.crt \
    && rm -f /tmp/ursim.tar.gz \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/ursim-entrypoint
COPY starturcontrol.sh /opt/ursim/starturcontrol.sh
COPY stopurcontrol.sh /opt/ursim/stopurcontrol.sh

RUN chmod 0755 \
        /usr/local/bin/ursim-entrypoint \
        /opt/ursim/starturcontrol.sh \
        /opt/ursim/stopurcontrol.sh

WORKDIR /opt/ursim

EXPOSE 29999 30001 30002 30003 30004 30011 30012 30013 30020

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/ursim-entrypoint"]
CMD ["UR7e"]
