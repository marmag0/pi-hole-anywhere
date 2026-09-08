#!/bin/bash

set -e
set -o pipefail

# usage: log [*/!/-/+] {message}
log() {
        local level="$1"
        local message="$2"
        local log_msg
        log_msg="[${level}] $(date): ${message}"
        echo "${log_msg}"
}

API_URL="http://127.0.0.1/api"
SID=""
UPSTREAMS='["1.1.1.1","1.0.0.1"]'
BLOCKLISTS=(
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
    "https://big.oisd.nl"
    "https://raw.githubusercontent.com/Spam404/Lists/master/main-blacklist.txt"
    "https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-pihole-filters/hostfile.txt"
    "https://urlhaus.abuse.ch/downloads/hostfile/"
)

logout() {
    if [ -n "${SID}" ]; then
        curl -sS --max-time 10 -X DELETE -H "X-FTL-SID: ${SID}" "${API_URL}/auth" > /dev/null || true
        SID=""
    fi
}

login() {
    local response
    local attempt
    for ((attempt=0; attempt<60; attempt++)); do
        if response=$(
            jq -n '{password: env.FTLCONF_webserver_api_password}' |
                curl -fsS --max-time 5 -H 'Content-Type: application/json' --data-binary @- "${API_URL}/auth"
        ); then
            if SID=$(jq -er 'select(.session.valid == true) | .session.sid | select(type == "string" and length > 0)' <<< "${response}"); then
                return 0
            fi
        fi
        sleep 1
    done
    log "!" "Error! Pi-hole API authentication failed. Check FTL and API_PASSWORD."
    return 1
}

api() {
    local method="$1"
    local path="$2"
    local response
    local args=()
    if [ "$#" -eq 3 ]; then
        args=(--data-binary "$3")
    fi
    response=$(curl -fsS --max-time 30 -X "${method}" -H "X-FTL-SID: ${SID}" \
        -H 'Content-Type: application/json' "${args[@]}" "${API_URL}/${path}")
    if ! jq -e '.error == null and ((.processed.errors // []) | length == 0)' <<< "${response}" > /dev/null; then
        log "!" "Error! Pi-hole rejected ${method} ${path}." >&2
        return 1
    fi
    printf '%s\n' "${response}"
}

trap logout EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if [ -z "${FTLCONF_webserver_api_password:-}" ]; then
    log "!" "Error! API_PASSWORD must be set in the Pi-hole container."
    exit 1
fi
login

CONFIG=$(api GET config/dns/upstreams)
if ! jq -e --argjson upstreams "${UPSTREAMS}" '.config.dns.upstreams == $upstreams' <<< "${CONFIG}" > /dev/null; then
    log "*" "Setting upstream DNS to 1.1.1.1 and 1.0.0.1..."
    api PATCH config "{\"config\":{\"dns\":{\"upstreams\":${UPSTREAMS}}}}" > /dev/null
    logout
    login
fi

LISTS=$(api GET 'lists?type=block')
for address in "${BLOCKLISTS[@]}"; do
    EXISTING=$(jq -c --arg address "${address}" '.lists[] | select(.address == $address)' <<< "${LISTS}")
    if [ -z "${EXISTING}" ]; then
        log "*" "Adding blocklist: ${address}"
        PAYLOAD=$(jq -n --arg address "${address}" '{address: $address, enabled: true, groups: [0]}')
        api POST 'lists?type=block' "${PAYLOAD}" > /dev/null
    elif ! jq -e '.enabled' <<< "${EXISTING}" > /dev/null; then
        log "*" "Enabling blocklist: ${address}"
        ENCODED=$(jq -rn --arg address "${address}" '$address | @uri')
        PAYLOAD=$(jq '{enabled: true, comment: .comment, groups: .groups}' <<< "${EXISTING}")
        api PUT "lists/${ENCODED}?type=block" "${PAYLOAD}" > /dev/null
    fi
done
logout

log "*" "Updating Gravity..."
pihole -g

LISTS=$(pihole-FTL sqlite3 -json /etc/pihole/gravity.db 'SELECT address,enabled,status FROM adlist WHERE type=0;')
FAILED=false
for address in "${BLOCKLISTS[@]}"; do
    if ! jq -e --arg address "${address}" '.[] | select(.address == $address) | .enabled == 1 and (.status == 1 or .status == 2)' <<< "${LISTS}" > /dev/null; then
        log "!" "Error! Gravity could not refresh blocklist: ${address}"
        FAILED=true
    fi
done
if [ "${FAILED}" == "true" ]; then
    exit 1
fi
log "+" "Pi-hole DNS and blocklist setup completed!"
