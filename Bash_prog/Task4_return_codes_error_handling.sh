#!/usr/bin/env bash
# -------------------------------------------------------------------------
# @title       Task4_return_codes_error_handling.sh
# @author      Emmanuel Gregory Opoku Owusu-Afriyie
# @index       4195524
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Demonstrates disciplined exit codes, traps, and error handling
# @date        $(date +%Y-%m-%d)
# -------------------------------------------------------------------------

# Exit codes:
#   0 = all checks passed
#   1 = missing required argument
#   2 = host unreachable
#   3 = insufficient disk space
#   4 = required config/data file not found or not readable
#   5 = required command not found

# 1. TRAP AND CLEANUP
# Create a temporary file in the /tmp directory to demonstrate the trap
TEMP_FILE=$(mktemp /tmp/task4_temp.XXXXXX)

cleanup() {
    echo -e "\n--- Cleanup Phase ---"
    if [ -f "$TEMP_FILE" ]; then
        rm -f "$TEMP_FILE"
        echo "Temporary file '$TEMP_FILE' successfully deleted."
    fi
}

# The trap catches EXIT (normal finish), INT (Ctrl+C), and TERM (kill signals)
# and automatically runs the cleanup function before the script completely stops.
trap cleanup EXIT INT TERM

# 2. USAGE GUIDE & INPUT VALIDATION
if [ "$#" -ne 1 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Usage: $0 <hostname>"
    echo "  <hostname>  The host/IP to ping for the network check"
    exit 1
fi

TARGET_HOST="$1"

# 3. HELPER FUNCTION
# Takes 4 arguments: (1) previous return code, (2) custom exit code, (3) fail msg, (4) pass msg
check_status() {
    local last_return_code=$1
    local target_exit_code=$2
    local fail_msg=$3
    local pass_msg=$4

    if [ "$last_return_code" -ne 0 ]; then
        echo "Error: $fail_msg (Exiting with code: $target_exit_code)" >&2
        exit "$target_exit_code"
    else
        echo "Success: $pass_msg"
    fi
}

echo "=== Starting System Checks ==="
echo "Writing status to temporary file..." > "$TEMP_FILE"

# CHECK 1: Is the host reachable? (Exit code 2)
echo -n "1. Checking network reachability to $TARGET_HOST... "
ping -c 1 -W 2 "$TARGET_HOST" > /dev/null 2>&1
check_status $? 2 "Host '$TARGET_HOST' is unreachable." "Host '$TARGET_HOST' responded."

# CHECK 2: Is there enough free disk space? (Exit code 3)
# Checks if root partition (/) has at least 1GB (1024MB) of free space
echo -n "2. Checking if root partition has > 1GB free... "
FREE_MB=$(df -m / | awk 'NR==2 {print $4}')
[ "$FREE_MB" -ge 1024 ]
check_status $? 3 "Insufficient disk space." "Disk space is sufficient ($FREE_MB MB free)."

# CHECK 3: Does a given config file exist and is it readable? (Exit code 4)
CONFIG_FILE="/etc/passwd"
echo -n "3. Checking if '$CONFIG_FILE' is readable... "
[ -r "$CONFIG_FILE" ]
check_status $? 4 "File '$CONFIG_FILE' is missing or unreadable." "File '$CONFIG_FILE' is accessible."

# CHECK 4: Is a given command/tool installed? (Exit code 5)
TOOL="curl"
echo -n "4. Checking if '$TOOL' is installed... "
command -v "$TOOL" > /dev/null 2>&1
check_status $? 5 "Command '$TOOL' is not installed." "Command '$TOOL' is installed."

echo "=== All checks passed successfully! ==="
exit 0
