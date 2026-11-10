#!/usr/bin/env bash
# Start the existing Docker stack on a container host with a persistent /data volume.
set -euo pipefail

umask 077
export BRIDGE_PORT="${BRIDGE_PORT:-${PORT:-8088}}"
export NIGHTY_EXE="${NIGHTY_EXE:-/data/Nighty.exe}"
export NIGHTY_STUB="${NIGHTY_STUB:-/data/Nighty_stub.exe}"
export NIGHTY_HOME="${NIGHTY_HOME:-/data/nighty}"
export NIGHTY_DIAG_DIR="${NIGHTY_DIAG_DIR:-/data/diagnostics}"

case "$BRIDGE_PORT" in
    ''|*[!0-9]*) echo 'ERROR: BRIDGE_PORT/PORT must be numeric.' >&2; exit 2 ;;
esac

mkdir -p /data "$NIGHTY_HOME" "$NIGHTY_DIAG_DIR" /data/dist/ws_extensions
if [ ! -w /data ]; then
    echo 'ERROR: /data is not writable. Check the volume mount and its user/group permissions.' >&2
    exit 2
fi

# Keep extensions on the volume while preserving the path Nighty expects.
if [ -d /app/dist ] && [ ! -L /app/dist ]; then
    rmdir /app/dist/ws_extensions 2>/dev/null || true
    if ! rmdir /app/dist; then
        echo 'ERROR: /app/dist must be empty so it can be linked to persistent /data/dist.' >&2
        exit 2
    fi
fi
if [ ! -e /app/dist ]; then
    ln -s /data/dist /app/dist
fi

if [ ! -s "$NIGHTY_EXE" ]; then
    if [ -z "${NIGHTY_EXE_URL:-}" ]; then
        echo 'ERROR: Nighty.exe is missing. Put your licensed copy at /data/Nighty.exe or set NIGHTY_EXE_URL and NIGHTY_EXE_SHA256.' >&2
        exit 2
    fi
    case "$NIGHTY_EXE_URL" in
        https://*) ;;
        *) echo 'ERROR: NIGHTY_EXE_URL must use HTTPS.' >&2; exit 2 ;;
    esac
    if [[ ! "${NIGHTY_EXE_SHA256:-}" =~ ^[[:xdigit:]]{64}$ ]]; then
        echo 'ERROR: Set NIGHTY_EXE_SHA256 to the 64-character SHA-256 of your executable.' >&2
        exit 2
    fi
    tmp="$(mktemp /data/.Nighty.exe.XXXXXXXX)"
    trap 'rm -f "$tmp"' EXIT
    if ! curl --fail --location --silent --show-error --max-time 600 --output "$tmp" "$NIGHTY_EXE_URL" 2>/dev/null; then
        echo 'ERROR: Could not download Nighty.exe from the configured private HTTPS URL.' >&2
        exit 2
    fi
    actual="$(sha256sum "$tmp")"
    if [ "${actual%% *}" != "${NIGHTY_EXE_SHA256,,}" ]; then
        echo 'ERROR: Nighty.exe SHA-256 does not match NIGHTY_EXE_SHA256.' >&2
        exit 2
    fi
    chmod 600 "$tmp"
    mv -f "$tmp" "$NIGHTY_EXE"
    trap - EXIT
fi

exec bash /app/scripts/docker-entrypoint.sh
