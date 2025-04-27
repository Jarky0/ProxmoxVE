#!/usr/bin/env bash

# Copyright (c) 2025 Tobias Walters / Jarky0
# Author: Tobias Walters / Jarky0
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.isc.org/kea/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH" || {
    echo "Failed to source functions"
    exit 1
}

# --- Standard Setup Steps ---
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# --- Application Specific Installation ---
msg_info "Installing Dependencies for Kea"
$STD apt-get install -y curl apt-transport-https || {
    msg_error "Failed to install dependencies"
    exit 1
}
msg_ok "Installed Dependencies"

msg_info "Installing ISC Kea DHCP Server"
if ! curl -fsSL 'https://dl.cloudsmith.io/public/isc/kea-2-6/setup.deb.sh' | bash -; then
    msg_error "Failed to add ISC Kea repository"
    exit 1
fi
$STD apt-get update || {
    msg_error "Failed to update package list after adding repo"
    exit 1
}
$STD apt-get install -y isc-kea || {
    msg_error "Failed to install isc-kea package"
    exit 1
}
systemctl enable --now isc-kea-dhcp4-server isc-kea-ctrl-agent || {
    msg_error "Failed to enable/start Kea services"
    exit 1
}
msg_ok "Installed and started ISC Kea DHCP Server with default configuration"

# --- Finalization ---
motd_ssh
customize
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
