#!/bin/bash

acquire_lock() {
    LOCK_DIR=".maintenance.lock"
    LOCK_OWNED=false

    if [ "${MAINTENANCE_LOCK_PID:-}" == "${PPID}" ] &&
        [ -f "${LOCK_DIR}/pid" ] &&
        [ "$(< "${LOCK_DIR}/pid")" == "${PPID}" ]; then
        return 0
    fi

    if ! mkdir "${LOCK_DIR}" 2> /dev/null; then
        log "!" "Error! Another maintenance operation is already running. Check .maintenance.lock if a previous run was interrupted."
        return 1
    fi

    LOCK_OWNED=true
    printf '%s\n' "$$" > "${LOCK_DIR}/pid"
    export MAINTENANCE_LOCK_PID="$$"
}

release_lock() {
    if [ "${LOCK_OWNED:-false}" == "true" ]; then
        rm -f "${LOCK_DIR}/pid"
        rmdir "${LOCK_DIR}"
        LOCK_OWNED=false
    fi
}
