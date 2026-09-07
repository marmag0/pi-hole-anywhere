#!/bin/bash

set -e

# ------------------- #
# prerequisites check #
# ------------------- #

TARGET_DIR="$1"

LOG_DIR="${HOME}/pi-hole/cron" # <-- adjust here
LOG_FILE="${LOG_DIR}/cron.log" # <-- adjust here

if [ ! -d "${LOG_DIR}" ]; then
        mkdir -p "${LOG_DIR}"
fi
if [ ! -f "${LOG_FILE}" ]; then
	touch "${LOG_FILE}"
fi

# usage: log [*/!/-/+] {message}
log() {
	local level="$1"
	local message="$2"
	local log_msg="[${level}] $(date): ${message}"
	echo "${log_msg}" >> "${LOG_FILE}"
}

log "*" "Running prerequisites tests..."

if [ -z "$TARGET_DIR" ]; then
	log "!" "Error! Target directory not specified! Usage: $0 /path/to/containers"
	echo "----------------------------------------" >> "${LOG_FILE}"
    	exit 1
fi

if ! cd "$TARGET_DIR" 2> /dev/null; then
	log "!" "Error! Directory does not exist: $TARGET_DIR"
    	echo "----------------------------------------" >> "${LOG_FILE}"
	exit 1
fi

PROJECT_NAME=$(basename "$(pwd)")


# -------------- #
# backup options #
# -------------- #

#BACKUP_DIR="/home/user/.../backup" # <-- adjust here
#BACKUPED_DIRS=("/home/user/.../etc-pihole" "/home/user/.../etc-dnsmasq.d") # <-- adjust here
#
#for dir in "${BACKUPED_DIRS[@]}"; do
#	if [ ! -d "${dir}" ]; then
#		log "!" "Error! Backup directory does not exist: ${dir}"
#		echo "----------------------------------------" >> "${LOG_FILE}"
#		exit 1
#	fi
#done
#
#if [ ! -d "${BACKUP_DIR}" ]; then
#        mkdir -p "${BACKUP_DIR}"
#fi
#
#log "*" "Creating volume backup..."
#tar -czvf "${BACKUP_DIR}/backup_$(date +%F).tar.gz" "${BACKUPED_DIRS[@]}" >> "${LOG_FILE}" 2>&1


# ------------- #
# docker update #
# ------------- #

PROJECT_NAME=$(basename "$(pwd)")
log "*" "[${PROJECT_NAME}]: Starting docker update..."

if docker compose pull >> "${LOG_FILE}" 2>&1 && docker compose up -d >> "${LOG_FILE}" 2>&1; then
	docker image prune -f >> "${LOG_FILE}" 2>&1
	log "+" "[$PROJECT_NAME]: Update successful!"
else
	log "!" "CRITICAL: Docker update failed! Check log file for details."
    echo "----------------------------------------" >> "${LOG_FILE}"
    exit 1
fi

echo "----------------------------------------" >> "${LOG_FILE}"
