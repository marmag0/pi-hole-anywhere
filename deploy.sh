#! /bin/bash

set -e

# usage: log [*/!/-/+] {message}
log() {
        local level="$1"
        local message="$2"
        local log_msg="[${level}] $(date): ${message}"
        echo "${log_msg}"
}

log "*" "Starting enhanced Pi-hole deployment..."

# Switching to script's directory
cd "$(dirname "$0")" || exit 1
log "*" "Checking all dependencies..."

# Checking if the flag exists and it's correct
FLAG="$1"
if [[ "${FLAG}" != "-d" && "${FLAG}" != "" ]]; then
	log "!" "Error: Flag ${FLAG} doesn't exists! Try '-d'."
	exit 1
fi

# Checking if Docker is running and user have permissions to use it
if ! docker info > /dev/null 2>&1; then
    log "!" "Error: Docker daemon is not running or you don't have permissions!"
    exit 1
fi

# Checking if docker-compose.yml is present in CWD of the script
if [ ! -f "docker-compose.yml" ]; then
    log "!" "Error: Docker Compose file not found in $(pwd)!"
    exit 1
fi

# Running Pi-hole using Docker
if [ "${FLAG}" == "-d" ]; then
	log "+" "Launching Pi-hole in detached mode..."
	echo "----------------------------------------"
	docker compose up -d
else
	log "+" "Launching Pi-hole in attached mode... Click 'd' to detach."
	echo "----------------------------------------"
	docker compose up
fi
