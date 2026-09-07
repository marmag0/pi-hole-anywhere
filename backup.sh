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

# Switching to script's directory
cd "$(dirname "$0")" || exit 1

if [ ! -f "backup.conf" ]; then
    log "!" "Error: Backup configuration file not found in $(pwd)! Copy backup.conf.example first."
    exit 1
fi

source backup.conf

if [ -z "${BACKUP_DIR}" ] || [ "${#BACKUPED_DIRS[@]}" -eq 0 ]; then
    log "!" "Error: Backup configuration is incomplete!"
    exit 1
fi

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
if ! sudo tar -czvf "${BACKUP_DIR}/backup_$(date +%F).tar.gz" "${BACKUPED_DIRS[@]}"; then
    log "!" "Error! Backup failed!"
    echo "----------------------------------------"
    exit 1
else
    log "+" "Backup completed successfully!"
    echo "----------------------------------------"
fi
