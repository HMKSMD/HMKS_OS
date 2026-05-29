#!/bin/bash
set -eoux pipefail

# ============================================================
# SECTION 1: Core Utilities
# ============================================================
rpm-ostree install \
    git \
    curl \
    wget \
    unzip \
    tar \
    zstd

# ============================================================
# SECTION 2: X11 & Display Stack
# ============================================================
rpm-ostree install \
    xorg-x11-server-Xorg \
    xorg-x11-drivers \
    xorg-x11-xauth \
    xorg-x11-xinit \
    xclip \
    xset \
    xrdb \
    xrandr \
    xinput \
    sddm

rpm-ostree install \
    libX11-devel \
    libXft-devel \
    libXinerama-devel \
    libXcursor-devel \
    libXrandr-devel \
    libXScrnSaver-devel \
    freetype-devel \
    fontconfig-devel

# ============================================================
# SECTION 3: Build Tools for oxwm
# ============================================================
rpm-ostree install \
    zig \
    lua \
    lua-devel \
    gcc \
    make \
    cmake

# ============================================================
# SECTION 4: Essential Desktop Utilities
# ============================================================
rpm-ostree install \
    NetworkManager \
    pipewire \
    pipewire-pulseaudio \
    pipewire-alsa \
    wireplumber \
    dunst \
    libnotify \
    nautilus \
    alacritty \
    jetbrains-mono-fonts \
    fira-code-fonts \
    fontawesome-fonts \
    polkit \
    gnome-keyring \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xsettingsd \
    udisks2 \
    rofi

# ============================================================
# SECTION 5: Brave Browser Nightly
# ============================================================
curl -fsSL https://brave-browser-rpm-nightly.s3.brave.com/brave-core-nightly.asc -o /tmp/brave-nightly.asc
rpm --import /tmp/brave-nightly.asc
cat > /etc/yum.repos.d/brave-browser-nightly.repo << 'EOF'
[brave-browser-nightly]
name=Brave Browser - Nightly
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-nightly.s3.brave.com/brave-core-nightly.asc
baseurl=https://brave-browser-rpm-nightly.s3.brave.com/$basearch
EOF
rpm-ostree install brave-origin-nightly

# ============================================================
# SECTION 6: Build OXWM from Source
# ============================================================
WORKDIR="/tmp/oxwm-build"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

git clone --depth 1 https://github.com/tonybanters/oxwm.git
cd oxwm

ZIG_GLOBAL_CACHE_DIR=/tmp/zig-cache zig build -Doptimize=ReleaseSmall

install -Dm755 zig-out/bin/oxwm /usr/bin/oxwm

mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/oxwm.desktop << 'EOF'
[Desktop Entry]
Name=OXWM
Comment=Dynamic tiling window manager (Zig-based, Lua-configured)
Exec=/usr/bin/oxwm
Type=Application
DesktopNames=OXWM
EOF

mkdir -p /etc/skel/.config/oxwm
if [ -f templates/config.lua ]; then
    cp templates/config.lua /etc/skel/.config/oxwm/
else
    cat > /etc/skel/.config/oxwm/config.lua << 'CFGEOF'
-- oxwm default config
terminal = "alacritty"
modkey = "Mod4"
CFGEOF
fi
cp LICENSE /usr/share/licenses/oxwm/ 2>/dev/null || true

cd /
rm -rf "$WORKDIR"

# ============================================================
# SECTION 7: Dunst Configuration
# ============================================================
mkdir -p /etc/skel/.config/dunst

cat > /etc/skel/.config/dunst/dunstrc << 'EOF'
[global]
    monitor = 0
    follow = none
    width = 300
    height = 100
    origin = top-right
    offset = 10x35
    scale = 0
    notification_limit = 5
    progress_bar = true
    progress_bar_height = 10
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    separator_height = 2
    padding = 8
    horizontal_padding = 8
    text_icon_padding = 0
    frame_width = 2
    frame_color = "#88c0d0"
    gap_size = 5
    separator_color = auto
    font = JetBrains Mono 10
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    min_icon_size = 0
    max_icon_size = 32
    icon_theme = "Adwaita"
    enable_recursive_icon_lookup = true
    sticky_history = yes
    history_length = 20
    dmenu = /usr/bin/rofi -dmenu
    browser = /usr/bin/xdg-open
    always_run_script = true
    title = Dunst
    class = Dunst
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[urgency_low]
    background = "#2e3440"
    foreground = "#d8dee9"
    frame_color = "#4c566a"
    timeout = 10

[urgency_normal]
    background = "#2e3440"
    foreground = "#d8dee9"
    frame_color = "#88c0d0"
    timeout = 10

[urgency_critical]
    background = "#bf616a"
    foreground = "#eceff4"
    frame_color = "#bf616a"
    timeout = 0

[brave]
    appname = "Brave"
    new_icon = brave

[slack]
    appname = "Slack"
    new_icon = slack
    timeout = 60

[spotify]
    appname = "Spotify"
    new_icon = spotify
    timeout = 10

[ignore]
    summary = "*"
    skip_display = true
EOF

mkdir -p /usr/share/licenses/dunst
cp /usr/share/doc/dunst/LICENSE /usr/share/licenses/dunst/ 2>/dev/null || true

# ============================================================
# SECTION 8: Enable Services
# ============================================================
systemctl enable sddm || true
systemctl enable NetworkManager || true
systemctl enable pipewire.socket || true
systemctl enable pipewire.service || true
systemctl enable wireplumber.service || true
systemctl enable polkit || true
systemctl enable udisks2 || true

mkdir -p /etc/systemd/user/default.target.wants
ln -s /usr/lib/systemd/user/dunst.service /etc/systemd/user/default.target.wants/dunst.service || true

# ============================================================
# SECTION 9: Install Homebrew
# ============================================================
mkdir -p /home/linuxbrew/.linuxbrew 2>/dev/null || true
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true

mkdir -p /etc/profile.d
cat > /etc/profile.d/brew.sh << 'BREWEOF'
# Homebrew setup
if [ -d /home/linuxbrew/.linuxbrew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -d ~/.linuxbrew ]; then
    eval "$(~/.linuxbrew/bin/brew shellenv)"
fi
BREWEOF

# ============================================================
# SECTION 10: Custom ujust Recipes
# ============================================================
mkdir -p /usr/share/ublue-os/just

cat > /usr/share/ublue-os/just/oxwm.just << 'EOF'
# vim: set ft=make :

rebase-stable:
    sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/HMKSMD/HMKS_OS:stable

rebase-latest:
    sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/HMKSMD/HMKS_OS:latest

init-config:
    #!/usr/bin/bash
    if [ ! -d "$HOME/.config/oxwm" ]; then
        mkdir -p "$HOME/.config/oxwm"
        cp /etc/skel/.config/oxwm/config.lua "$HOME/.config/oxwm/"
        echo "Default oxwm config copied to ~/.config/oxwm/"
    else
        echo "Config already exists at ~/.config/oxwm/"
    fi

init-dunst:
    #!/usr/bin/bash
    if [ ! -d "$HOME/.config/dunst" ]; then
        mkdir -p "$HOME/.config/dunst"
        cp /etc/skel/.config/dunst/dunstrc "$HOME/.config/dunst/"
        echo "Default dunst config copied to ~/.config/dunst/dunstrc"
    else
        echo "Dunst config already exists at ~/.config/dunst/"
    fi

init-alacritty:
    #!/usr/bin/bash
    if [ ! -d "$HOME/.config/alacritty" ]; then
        mkdir -p "$HOME/.config/alacritty"
        cat > "$HOME/.config/alacritty/alacritty.toml" << 'INNEREOF'
[font]
normal = { family = "JetBrains Mono", style = "Regular" }
size = 10.0

[colors.primary]
background = "#2e3440"
foreground = "#d8dee9"

[colors.normal]
black = "#3b4252"
red = "#bf616a"
green = "#a3be8c"
yellow = "#ebcb8b"
blue = "#81a1c1"
magenta = "#b48ead"
cyan = "#88c0d0"
white = "#e5e9f0"

[window]
padding = { x = 4, y = 4 }
opacity = 1.0

[scrolling]
history = 10000
multiplier = 3

[cursor]
style = "Block"
unfocused_hollow = true
INNEREOF
        echo "Default alacritty config created at ~/.config/alacritty/alacritty.toml"
    else
        echo "Alacritty config already exists"
    fi

test-notify:
    notify-send "Test Notification" "Dunst is working correctly on OXWM!" --icon=dialog-information

setup-flatpak:
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

update-all:
    #!/usr/bin/bash
    echo "Updating system image..."
    rpm-ostree upgrade
    echo "Updating flatpaks..."
    flatpak update -y
    if command -v brew &>/dev/null; then
        echo "Updating homebrew..."
        brew update && brew upgrade
    fi

image-info:
    #!/usr/bin/bash
    echo "Current deployment:"
    rpm-ostree status
    echo ""
    echo "Image source:"
    ostree remote list

reload-dunst:
    #!/usr/bin/bash
    killall dunst 2>/dev/null || true
    dunst &
    echo "Dunst restarted"

mount-info:
    #!/usr/bin/bash
    echo "=== Current Mounts ==="
    findmnt -t ext4,xfs,btrfs,vfat,exfat,ntfs,fuseblk
    echo ""
    echo "=== USB/External Devices ==="
    lsblk -p -o NAME,SIZE,FSTYPE,MOUNTPOINT,MODEL
EOF

# ============================================================
# SECTION 11: Auto-Update Configuration
# ============================================================
mkdir -p /etc/xdg/topgrade
cat > /etc/xdg/topgrade/topgrade.toml << 'EOF'
[flatpak]
use_sudo = false
assume_yes = true

[distrobox]
use_sudo = false

[firmware]
upgrade = false

[linux]
rpm_ostree = true
EOF

# ============================================================
# SECTION 12: X11 Session Configuration
# ============================================================
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/10-x11.conf << 'EOF'
[General]
DisplayServer=x11
EOF

mkdir -p /etc/X11/xinit/xinitrc.d
cat > /etc/X11/xinit/xinitrc.d/99-oxwm.sh << 'EOF'
#!/bin/bash
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax)
fi

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=oxwm
export XDG_CURRENT_DESKTOP=oxwm
export DESKTOP_SESSION=oxwm

if ! pgrep -x dunst > /dev/null; then
    dunst &
fi

if ! pgrep -x xsettingsd > /dev/null; then
    xsettingsd &
fi
EOF
chmod +x /etc/X11/xinit/xinitrc.d/99-oxwm.sh

# ============================================================
# SECTION 13: Cleanup
# ============================================================
rm -rf /var/cache/rpm-ostree
rm -rf /tmp/*
