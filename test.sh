#!/usr/bin/env bash
#
# test.sh - integration tests for the diagnostic-tool Docker image
#
# Builds the image (unless SKIP_BUILD=1) and runs it via `docker run`,
# asserting on stdout/stderr content and exit codes.
#
# Usage: ./test.sh

set -uo pipefail

IMAGE="diagnostic-tool"
PASS=0
FAIL=0

log_pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
log_fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

# assert_exit_code <expected> <actual> <description>
assert_exit_code() {
    local expected="$1" actual="$2" desc="$3"
    if [ "${actual}" -eq "${expected}" ]; then
        log_pass "${desc} (exit code ${actual})"
    else
        log_fail "${desc} (expected exit ${expected}, got ${actual})"
    fi
}

# assert_contains <haystack> <needle> <description>
assert_contains() {
    local haystack="$1" needle="$2" desc="$3"
    if echo "${haystack}" | grep -qF -- "${needle}"; then
        log_pass "${desc}"
    else
        log_fail "${desc} (expected output to contain: '${needle}')"
    fi
}

echo "=== Building image: ${IMAGE} ==="
if [ "${SKIP_BUILD:-0}" != "1" ]; then
    if ! docker build -t "${IMAGE}" . >/tmp/test_sh_build.log 2>&1; then
        echo "Docker build failed:"
        cat /tmp/test_sh_build.log
        exit 1
    fi
fi
rm -f /tmp/test_sh_build.log

run_image() {
    docker run --rm "${IMAGE}" "$@"
}

echo
echo "=== Test: help ==="
output="$(run_image help 2>&1)"; code=$?
assert_exit_code 0 "${code}" "help exits successfully"
assert_contains "${output}" "Usage:" "help shows usage"
assert_contains "${output}" "system" "help lists 'system' command"
assert_contains "${output}" "network" "help lists 'network' command"
assert_contains "${output}" "disk" "help lists 'disk' command"

echo
echo "=== Test: system ==="
output="$(run_image system 2>&1)"; code=$?
assert_exit_code 0 "${code}" "system exits successfully"
assert_contains "${output}" "System Information" "system shows header"
assert_contains "${output}" "Kernel" "system shows kernel info"
assert_contains "${output}" "Architecture" "system shows architecture info"

echo
echo "=== Test: disk ==="
output="$(run_image disk 2>&1)"; code=$?
assert_exit_code 0 "${code}" "disk exits successfully"
assert_contains "${output}" "Disk Information" "disk shows header"
assert_contains "${output}" "Filesystem" "disk shows filesystem table"

echo
echo "=== Test: invalid command ==="
output="$(run_image bogus-command 2>&1)"; code=$?
assert_exit_code 2 "${code}" "invalid command exits with code 2"
assert_contains "${output}" "Error" "invalid command shows an error"

echo
echo "=== Test: no command provided ==="
output="$(run_image 2>&1)"; code=$?
# ENTRYPOINT/CMD default to 'help', which should succeed.
assert_exit_code 0 "${code}" "no args falls back to help (exit 0)"
assert_contains "${output}" "Usage:" "no args shows usage"

echo
echo "=== Test: network missing host argument ==="
output="$(run_image network 2>&1)"; code=$?
assert_exit_code 2 "${code}" "network without host exits with code 2"
assert_contains "${output}" "Error" "network without host shows an error"

echo
echo "=== Test: network with valid host ==="
output="$(run_image network 127.0.0.1 2>&1)"; code=$?
assert_exit_code 0 "${code}" "network to a reachable host exits with code 0"
assert_contains "${output}" "reachable" "network reports reachable host"

echo
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "${FAIL}" -gt 0 ]; then
    exit 1
fi
exit 0
