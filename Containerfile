# ============================================================
# Base Image Selection - NVIDIA VERSION
# ============================================================
FROM ghcr.io/ublue-os/base-nvidia:41

# ============================================================
# Homebrew Layer
# ============================================================
COPY --from=ghcr.io/ublue-os/brew:41 /usr/share/homebrew.tar.zst /usr/share/homebrew.tar.zst
COPY --from=ghcr.io/ublue-os/brew:41 /usr/lib/systemd/system/brew-setup.service /usr/lib/systemd/system/
COPY --from=ghcr.io/ublue-os/brew:41 /usr/lib/systemd/system/brew-update.service /usr/lib/systemd/system/
COPY --from=ghcr.io/ublue-os/brew:41 /usr/lib/systemd/system/brew-upgrade.service /usr/lib/systemd/system/
COPY --from=ghcr.io/ublue-os/brew:41 /etc/profile.d/brew.sh /etc/profile.d/
COPY --from=ghcr.io/ublue-os/brew:41 /etc/security/limits.d/brew.conf /etc/security/limits.d/
COPY --from=ghcr.io/ublue-os/brew:41 /usr/lib/tmpfiles.d/brew.conf /usr/lib/tmpfiles.d/

# ============================================================
# Build Scripts
# ============================================================
COPY build_files /tmp/build_files

# ============================================================
# Run Customization
# ============================================================
RUN /tmp/build_files/build.sh && \
    ostree container commit

# ============================================================
# Metadata
# ============================================================
LABEL org.opencontainers.image.title="HMKS_OS"
LABEL org.opencontainers.image.description="Aurora-inspired minimal NVIDIA image with OXWM window manager"
LABEL org.opencontainers.image.source="https://github.com/HMKSMD/HMKS_OS"
