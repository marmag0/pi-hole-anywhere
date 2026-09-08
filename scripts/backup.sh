#!/bin/bash

set -e
umask 077

# Usage: log [*/!/-/+] "message"
log() {
        local level="$1"
        local message="$2"
        local log_msg
        log_msg="[${level}] $(date): ${message}"
        echo "${log_msg}"
}

log "*" "Starting backup process..."

# Resolve relative paths from the project folder
cd "$(dirname "$0")/.." || exit 1

if [ ! -f "config/backup.conf" ]; then
    log "!" "Error: Backup configuration file not found in $(pwd)/config! Copy config/backup.conf.example first."
    exit 1
fi

# shellcheck source=config/backup.conf.example
source ./config/backup.conf
source ./scripts/maintenance.sh

if [ -z "${BACKUP_DIR}" ] || [ "${#BACKUPED_DIRS[@]}" -eq 0 ]; then
    log "!" "Error: Backup configuration is incomplete!"
    exit 1
fi

PIHOLE_STOPPED=false
BACKUP_FILE=""

cleanup() {
    local result=$?
    trap - EXIT
    if [ -n "${BACKUP_FILE}" ] && [ -f "${BACKUP_FILE}" ]; then
        rm -f -- "${BACKUP_FILE}" || result=1
    fi
    if [ "${PIHOLE_STOPPED}" == "true" ]; then
        if ! docker compose start pihole; then
            log "!" "Error! Pi-hole could not be restarted automatically."
            result=1
        fi
    fi
    release_lock || result=1
    exit "${result}"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
acquire_lock

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

BACKUP_DIR=$(cd "${BACKUP_DIR}" && pwd -P)
for dir in "${BACKUPED_DIRS[@]}"; do
    SOURCE_DIR=$(cd "${dir}" && pwd -P)
    if [[ "${BACKUP_DIR}/" == "${SOURCE_DIR%/}/"* ]]; then
        log "!" "Error! Backup directory must be outside the directories being archived."
        exit 1
    fi
done
# Keep incomplete archives separate from completed .tar.gz files
BACKUP_FILE=$(mktemp "${BACKUP_DIR}/backup_$(date +%F_%H-%M-%S).XXXXXX")

PIHOLE_RUNNING=$(docker compose ps --status running -q pihole)
if [ -n "${PIHOLE_RUNNING}" ]; then
    log "*" "Stopping Pi-hole for a consistent backup..."
    PIHOLE_STOPPED=true
    docker compose stop pihole
fi

log "*" "Creating volume backup..."
if ! sudo tar -czvf "${BACKUP_FILE}" -- "${BACKUPED_DIRS[@]}"; then
    log "!" "Error! Backup failed!"
    echo "----------------------------------------"
    exit 1
else
    mv -- "${BACKUP_FILE}" "${BACKUP_FILE}.tar.gz"
    BACKUP_FILE=""
    log "+" "Backup completed successfully!"
    echo "----------------------------------------"
fi
