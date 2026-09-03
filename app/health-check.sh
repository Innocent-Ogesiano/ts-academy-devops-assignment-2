#!/usr/bin/env bash
#
# health-check.sh - container health check for the diagnostic CLI
#
# Used as the Docker HEALTHCHECK command. Verifies that diagnostic.sh
# is present, executable, and able to run its core commands successfully.
#
# Exit codes (Docker healthcheck convention):
#   0 - healthy
#   1 - unhealthy

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIAGNOSTIC="${SCRIPT_DIR}/diagnostic.sh"

if [ ! -x "${DIAGNOSTIC}" ]; then
    echo "unhealthy: ${DIAGNOSTIC} not found or not executable" >&2
    exit 1
fi

if ! "${DIAGNOSTIC}" system >/dev/null 2>&1; then
    echo "unhealthy: 'diagnostic system' failed" >&2
    exit 1
fi

if ! "${DIAGNOSTIC}" disk >/dev/null 2>&1; then
    echo "unhealthy: 'diagnostic disk' failed" >&2
    exit 1
fi

echo "healthy"
exit 0
