#!/bin/bash

set -e

# ------------------- #
# prerequisites check #
# ------------------- #

TARGET_DIR="${1:-}"

# usage: log [*/!/-/+] {message}
log() {
	local level="$1"
	local message="$2"
	local log_msg
	log_msg="[${level}] $(date): ${message}"
	echo "${log_msg}"
}

log "*" "Running prerequisites tests..."

if [ -z "$TARGET_DIR" ]; then
	log "!" "Error! Target directory not specified! Usage: $0 /path/to/containers"
	echo "----------------------------------------"
    	exit 1
fi

if ! cd "$TARGET_DIR" 2> /dev/null; then
	log "!" "Error! Directory does not exist: $TARGET_DIR"
	echo "----------------------------------------"
	exit 1
fi

PROJECT_NAME=$(basename "$(pwd)")

if [ ! -f "docker-compose.yml" ]; then
	log "!" "Error! Docker Compose file not found in $(pwd)!"
	exit 1
fi

LOG_FILE="cron/cron.log"
BACKUP_BEFORE_UPDATE=false

if [ -f "update.conf" ]; then
	log "!" "Error! Move update.conf to config/update.conf before running updates."
	exit 1
fi

if [ -f "config/update.conf" ]; then
	# shellcheck source=config/update.conf.example
	source ./config/update.conf
fi

if [ -z "${LOG_FILE}" ] || [[ "${BACKUP_BEFORE_UPDATE}" != "true" && "${BACKUP_BEFORE_UPDATE}" != "false" ]]; then
	log "!" "Error! Set LOG_FILE and BACKUP_BEFORE_UPDATE (true or false) in config/update.conf."
	exit 1
fi

mkdir -p "$(dirname "${LOG_FILE}")"
exec >> "${LOG_FILE}" 2>&1

source ./scripts/maintenance.sh
trap release_lock EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
acquire_lock

docker compose config --quiet

if [ "${BACKUP_BEFORE_UPDATE}" == "true" ]; then
	log "*" "Creating backup before update..."
	if ! bash ./scripts/backup.sh; then
		log "!" "CRITICAL: Backup failed! Update canceled."
		exit 1
	fi
fi

# ------------- #
# docker update #
# ------------- #

log "*" "[${PROJECT_NAME}]: Starting docker update..."

if docker compose pull && docker compose up -d --wait --wait-timeout 180; then
	log "+" "[$PROJECT_NAME]: Update successful!"
else
	log "!" "CRITICAL: Docker update failed! Check log file for details."
    echo "----------------------------------------"
    exit 1
fi

echo "----------------------------------------"
