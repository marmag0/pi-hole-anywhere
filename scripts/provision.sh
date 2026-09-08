#!/bin/bash

set -e

# Usage: log [*/!/-/+] "message"
log() {
        local level="$1"
        local message="$2"
        local log_msg
        log_msg="[${level}] $(date): ${message}"
        echo "${log_msg}"
}

cd "$(dirname "$0")/.." || exit 1
source ./scripts/maintenance.sh

trap release_lock EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
acquire_lock

log "*" "Starting Pi-hole and waiting for the dashboard..."
docker compose up -d --wait --wait-timeout 180 pihole

log "*" "Applying the README DNS and blocklist settings..."
docker compose exec -T --user root pihole bash -s < ./scripts/provision-pihole.sh
