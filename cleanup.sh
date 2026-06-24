#! /bin/bash

set -e

# usage: log [*/!/-/+] {message}
log() {
        local level="$1"
        local message="$2"
        local log_msg="[${level}] $(date): ${message}"
        echo "${log_msg}"
}

log "*" "Starting compleate cleanup process..."

# Switching to script's directory
cd "$(dirname "$0")" || exit 1
log "*" "Checking all dependencies..."

# Checking if docker-compose.yml is present in CWD of the script
if [ ! -f "docker-compose.yml" ]; then
    log "!" "Error: Docker Compose file not found in $(pwd)!"
    exit 1
fi

# Getting confirmation from user
OUTCOME=""
echo "You are about to take down your Pi-hole with all it's saved data!"
echo "This operation is irreversable, unleass you've backed up your volume..."
read -r -p "Are you sure? [Y/n] " ans
case $ans in
	[Yy]|[Yy][Ee][Ss] ) OUTCOME="yes" ;;
	[Nn]|[Nn][Oo] )     OUTCOME="no" ;;
	* )                 OUTCOME="error" ;;
esac

# Taking action based on confirmation
if [ "${OUTCOME}" == "no" ]; then
	log "-" "Canceling cleanup process... Pi-hole not affected."
	exit 1
elif [ "${OUTCOME}" == "error" ]; then
	log "!" "Error: ${ans} is not a valid selection!"
	exit 1
elif [ "${OUTCOME}" == "yes" ]; then
	log "*" "Performing cleanup"
else
	log "!" "Unexpected error! Exiting..."
	exit 1
fi

# Stopping and removing Docker containers
log "*" "Removing Docker containers, networks and volumes..."
docker compose down -v
docker system prune -f

# Removing volume files
log "*" "Removing any other volume files..."
if [ -d "etc-pihole" ]; then
	rm -rf etc-pihole
fi

log "+" "Cleanup process completed!"
echo "----------------------------------------"
