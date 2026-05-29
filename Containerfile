FROM ghcr.io/ublue-os/base-nvidia:latest

COPY build_files /tmp/build_files

RUN /tmp/build_files/build.sh && \
    ostree container commit

LABEL org.opencontainers.image.title="HMKS_OS"
LABEL org.opencontainers.image.description="Aurora-inspired minimal NVIDIA image with OXWM window manager"
LABEL org.opencontainers.image.source="https://github.com/HMKSMD/HMKS_OS"
