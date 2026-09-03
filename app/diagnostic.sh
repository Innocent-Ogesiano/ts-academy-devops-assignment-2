#!/usr/bin/env bash
#
# diagnostic.sh - simple Linux diagnostic CLI
#
# Usage:
#   diagnostic system
#   diagnostic network <host>
#   diagnostic disk
#   diagnostic help
#
# Exit codes:
#   0 - success
#   1 - operational/runtime failure
#   2 - invalid command or input

set -uo pipefail

PROG_NAME="$(basename "$0")"

print_usage() {
    cat <<EOF
Usage: ${PROG_NAME} <command> [arguments]

Commands:
  system              Display system information (OS, kernel, CPU, memory, uptime)
  network <host>      Check network connectivity to the given host
  disk                Display disk usage information
  help                Display this help message

Exit codes:
  0    success
  1    operational/runtime failure
  2    invalid command or input
EOF
}

cmd_system() {
    echo "=== System Information ==="

    if command -v hostname >/dev/null 2>&1; then
        echo "Hostname       : $(hostname)"
    fi

    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "OS             : ${PRETTY_NAME:-unknown}"
    else
        echo "OS             : $(uname -s)"
    fi

    echo "Kernel         : $(uname -r)"
    echo "Architecture   : $(uname -m)"

    if command -v uptime >/dev/null 2>&1; then
        echo "Uptime         : $(uptime -p 2>/dev/null || uptime)"
    fi

    if command -v nproc >/dev/null 2>&1; then
        echo "CPU Cores      : $(nproc)"
    elif [ -r /proc/cpuinfo ]; then
        echo "CPU Cores      : $(grep -c ^processor /proc/cpuinfo)"
    fi

    if [ -r /proc/meminfo ]; then
        local mem_total mem_avail
        mem_total="$(awk '/MemTotal/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo)"
        mem_avail="$(awk '/MemAvailable/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo)"
        echo "Memory Total   : ${mem_total}"
        echo "Memory Available: ${mem_avail}"
    elif command -v free >/dev/null 2>&1; then
        free -h
    fi

    return 0
}

cmd_network() {
    if [ "$#" -eq 0 ]; then
        echo "Error: 'network' requires a <host> argument" >&2
        print_usage >&2
        exit 2
    fi

    local host="$1"
    echo "=== Network Check: ${host} ==="

    if ! command -v ping >/dev/null 2>&1; then
        echo "Error: 'ping' command not found" >&2
        exit 1
    fi

    if ping -c 3 -W 2 "${host}" >/tmp/diagnostic_ping.$$ 2>&1; then
        cat /tmp/diagnostic_ping.$$
        rm -f /tmp/diagnostic_ping.$$
        echo "Result         : ${host} is reachable"
        return 0
    else
        cat /tmp/diagnostic_ping.$$
        rm -f /tmp/diagnostic_ping.$$
        echo "Result         : ${host} is unreachable" >&2
        exit 1
    fi
}

cmd_disk() {
    echo "=== Disk Information ==="

    if command -v df >/dev/null 2>&1; then
        df -h
    else
        echo "Error: 'df' command not found" >&2
        exit 1
    fi

    return 0
}

main() {
    if [ "$#" -eq 0 ]; then
        echo "Error: no command provided" >&2
        print_usage >&2
        exit 2
    fi

    local command="$1"
    shift

    case "${command}" in
        system)
            cmd_system "$@"
            ;;
        network)
            cmd_network "$@"
            ;;
        disk)
            cmd_disk "$@"
            ;;
        help|-h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Error: invalid command '${command}'" >&2
            print_usage >&2
            exit 2
            ;;
    esac
}

main "$@"
