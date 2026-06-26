#!/bin/bash

set -e

# usage: log [*/!/-/+] {message}
log() {
        local level="$1"
        local message="$2"
        local log_msg="[${level}] $(date): ${message}"
        echo "${log_msg}"
}

log "*" "Starting backup process..."

BACKUP_DIR="/home/user/..." # <-- adjust here
BACKUPED_DIRS=("/home/user/.../etc-pihole" "/home/user/.../etc-dnsmasq.d") # <-- adjust here

for dir in "${BACKUPED_DIRS[@]}"; do
	if [ ! -d "${dir}" ]; then
		log "!" "Error! Directory/ies to be backed up does not exist: ${dir}"
		echo "----------------------------------------"
		exit 1
	fi
done

if [ ! -d "${BACKUP_DIR}" ]; then
        mkdir -p "${BACKUP_DIR}"
fi

log "*" "Creating volume backup..."
if ! tar -czvf "${BACKUP_DIR}/backup_$(date +%F).tar.gz" "${BACKUPED_DIRS[@]}"; then
    log "!" "Error! Backup failed!"
    echo "----------------------------------------"
    exit 1
else
    log "+" "Backup completed successfully!"
    echo "----------------------------------------"
fi
