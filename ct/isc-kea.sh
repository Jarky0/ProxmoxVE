#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jarky0/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2025 Tobias Walters / Jarky0
# Author: Tobias Walters / Jarky0
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.isc.org/kea/

APP="ISC Kea"
var_tags="${var_tags:-dhcp}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info "$APP"

    if [[ ! -f /etc/kea/kea-dhcp4.conf ]]; then
        msg_error "No ${APP} Installation Found!"
        exit 1
    fi

    msg_info "Checking for ${APP} updates..."
    apt-get update

    if apt list --upgradable 2>/dev/null | grep -q 'isc-kea'; then
        msg_info "${APP} update available. Proceeding with update..."

        msg_info "Creating backup of /etc/kea..."
        local backup_date=$(date +%Y%m%d_%H%M%S)
        if tar -czf "/opt/${APP}_backup_${backup_date}.tar.gz" /etc/kea; then
            msg_ok "Backup created at /opt/${APP}_backup_${backup_date}.tar.gz"
        else
            msg_error "Backup failed!"
            exit 1
        fi

        msg_info "Stopping ${APP} services..."
        systemctl stop isc-kea-dhcp4-server isc-kea-ctrl-agent || msg_warning "Could not stop Kea services (maybe not running?)"
        msg_ok "Attempted to stop ${APP} services."

        msg_info "Updating ${APP} package..."
        apt-get upgrade -y isc-kea || {
            msg_error "Failed to upgrade ${APP} package!"
            exit 1
        }
        msg_ok "${APP} package updated."

        msg_info "Starting ${APP} services..."
        systemctl start isc-kea-dhcp4-server isc-kea-ctrl-agent || {
            msg_error "Failed to start Kea services after update!"
            exit 1
        }
        msg_ok "${APP} services started."

        msg_ok "Update process completed successfully."
    else
        msg_ok "No update required. ${APP} is already up-to-date."
    fi
    exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO} Kea was installed and started with default settings."
echo -e "${INFO} Access the container console using: pct enter $CTID"
echo -e "${INFO} Adjust the configuration manually at: /etc/kea/kea-dhcp4.conf (inside the container)"

exit 0
