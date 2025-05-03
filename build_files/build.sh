#!/bin/bash

RELEASE="$(rpm -E %fedora)"
set -ouex pipefail

enable_copr() {
    repo="$1"
    repo_with_dash="${repo/\//-}"
    wget "https://copr.fedorainfracloud.org/coprs/${repo}/repo/fedora-${RELEASE}/${repo_with_dash}-fedora-${RELEASE}.repo" \
        -O "/etc/yum.repos.d/_copr_${repo_with_dash}.repo"
}

# # https://support.1password.com/install-linux/#fedora-or-red-hat-enterprise-linux
# get_1_password() {
#     rpm --import https://downloads.1password.com/linux/keys/1password.asc
#     sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
#     mkdir /opt/1Password
# }

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

enable_copr solopasha/hyprland
enable_copr erikreider/SwayNotificationCenter
enable_copr pgdev/ghostty
enable_copr wezfurlong/wezterm-nightly

# ncurses-term dependency is in conflict with ghostty so I'm getting rid of fish here
dnf5 remove -y fish

dnf5 install -y --setopt=install_weak_deps=False \
    xdg-desktop-portal-hyprland \
    hyprland \
    hyprlock \
    hypridle \
    hyprpicker \
    hyprsysteminfo \
    hyprsunset \
    hyprpaper \
    hyprcursor \
    hyprgraphics \
    hyprpolkitagent \
    hyprland-qtutils \
    hyprland-qt-support \
    hyprland-uwsm \
    uwsm \
    pyprland \
    waybar \
    wofi \
    rofi \
    swaync \
    wl-clipboard \
    grim \
    brightnessctl \
    pavucontrol \
    network-manager-applet \
    clipman \
    nwg-drawer \
    wdisplays \
    pavucontrol \
    SwayNotificationCenter \
    NetworkManager-tui \
    tmux \
    ghostty \
    wezterm \
    blueman \
    qt5-qtwayland \
    qt6-qtwayland

# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable solopasha/hyprland
# dnf5 -y copr disable erikreider/SwayNotificationCenter
# dnf5 -y copr disable pgdev/ghostty

#### Example for enabling a System Unit File

# experimenting to get hyprlock to work
# echo "auth required pam_unix.so" >/etc/pam.d/hyprlock
# echo "auth include system-auth" >/etc/pam.d/hyprlock
# systemctl enable podman.socket
mkdir -p /nix/var/nix/gcroots/per-user/bazzite
