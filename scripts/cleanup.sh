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

log "*" "Starting complete cleanup process..."

# Resolve relative paths from the project folder
cd "$(dirname "$0")/.." || exit 1
log "*" "Checking all dependencies..."

# Check that this is the project folder before allowing cleanup
if [ ! -f "docker-compose.yml" ]; then
    log "!" "Error: Docker Compose file not found in $(pwd)!"
    exit 1
fi

# Require confirmation before deleting saved data
OUTCOME=""
echo "You are about to take down your Pi-hole with all its saved data!"
echo "This operation is irreversible unless you've backed up your volume..."
read -r -p "Are you sure? [y/N] " ans
case $ans in
	[Yy]|[Yy][Ee][Ss] ) OUTCOME="yes" ;;
	[Nn]|[Nn][Oo]|"" )  OUTCOME="no" ;;
	* )                 OUTCOME="error" ;;
esac

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

# Hold the maintenance lock until containers and saved data are removed
source ./scripts/maintenance.sh
trap release_lock EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
acquire_lock
log "*" "Removing Docker containers, networks and volumes..."
docker compose down -v --remove-orphans

# Compose leaves bind-mounted data on the host
log "*" "Removing any other volume files..."
if [ -d "etc-pihole" ]; then
	rm -rf etc-pihole
fi
if [ -d "etc-dnsmasq.d" ]; then
	rm -rf etc-dnsmasq.d
fi

log "+" "Cleanup process completed!"
echo "----------------------------------------"
