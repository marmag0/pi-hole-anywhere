#! /bin/bash

set -e

# Usage: log [*/!/-/+] "message"
log() {
        local level="$1"
        local message="$2"
        local log_msg
        log_msg="[${level}] $(date): ${message}"
        echo "${log_msg}"
}

log "*" "Starting enhanced Pi-hole deployment..."

# Resolve relative paths from the project folder
cd "$(dirname "$0")/.." || exit 1
log "*" "Checking all dependencies..."

# Accept only the optional detached-mode flag
FLAG="${1:-}"
if [ "$#" -gt 1 ] || [[ "${FLAG}" != "-d" && "${FLAG}" != "" ]]; then
	log "!" "Error: Invalid arguments! Try '-d'."
	exit 1
fi

# Check Docker availability and permissions
if ! docker info > /dev/null 2>&1; then
    log "!" "Error: Docker daemon is not running or you don't have permissions!"
    exit 1
fi

if [ ! -f "docker-compose.yml" ]; then
    log "!" "Error: Docker Compose file not found in $(pwd)!"
    exit 1
fi

if [ ! -f ".env" ]; then
    log "!" "Error: .env file not found in $(pwd)! Copy config/.env.example first."
    exit 1
fi

if ! docker compose config --quiet; then
    log "!" "Error: Docker Compose configuration is invalid!"
    exit 1
fi

# Hold the maintenance lock through provisioning and startup, not log following
source ./scripts/maintenance.sh
trap release_lock EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
acquire_lock
bash ./scripts/provision.sh
docker compose up -d --wait --wait-timeout 180
release_lock

if [ "${FLAG}" == "-d" ]; then
	log "+" "Pi-hole is running in detached mode!"
	echo "----------------------------------------"
else
	log "+" "Following logs... Press Ctrl+C to stop following without stopping Pi-hole."
	echo "----------------------------------------"
	docker compose logs --follow
fi
