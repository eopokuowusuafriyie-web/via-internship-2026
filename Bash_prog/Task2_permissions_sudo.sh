#!/usr/bin/env bash
# -------------------------------------------------------------------------
# @title       Task2_permissions_sudo.sh
# @author      Emmanuel Gregory Opoku Owusu-Afriyie
# @index       4195524
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Manages file permissions and demonstrates sudo/root checks
# @date        $(date +%Y-%m-%d)
# -------------------------------------------------------------------------

# 1. USAGE GUIDE & INPUT VALIDATION
if [ "$#" -ne 1 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Usage: $0 <file-path>"
    echo "  <file-path>  The file to check and modify permissions on"
    exit 1
fi

TARGET_FILE="$1"

# Validate that the file actually exists before we try to manipulate it
if [ ! -e "$TARGET_FILE" ]; then
    echo "Error: File '$TARGET_FILE' does not exist." >&2
    exit 1
fi

echo "--- 1. Initial Permissions ---"
# %A gets the symbolic format (e.g. -rw-r--r--), %a gets the numeric format (e.g. 644)
SYM_PERMS=$(stat -c "%A" "$TARGET_FILE")
NUM_PERMS=$(stat -c "%a" "$TARGET_FILE")
echo "Current permissions for '$TARGET_FILE':"
echo "  Symbolic: $SYM_PERMS"
echo "  Numeric:  $NUM_PERMS"
echo ""

echo "--- 2. Changing Permissions ---"
echo "Demonstrating numeric chmod (setting to 644)..."
chmod 644 "$TARGET_FILE"
if [ $? -ne 0 ]; then
    echo "Error: Failed to apply numeric chmod." >&2
    exit 1
fi
echo "Success: Set to 644."

echo "Demonstrating symbolic chmod (adding execute for user: u+x)..."
chmod u+x "$TARGET_FILE"
if [ $? -ne 0 ]; then
    echo "Error: Failed to apply symbolic chmod." >&2
    exit 1
fi
echo "Success: Applied u+x."
echo ""

echo "--- 3. Checking Sudo / Root Privileges ---"
# id -u returns 0 if the user is root, or a higher number if it is a normal user
if [ "$(id -u)" -eq 0 ]; then
    echo "Root privileges detected. Attempting to change ownership to root..."
    chown root "$TARGET_FILE"
    if [ $? -ne 0 ]; then
        echo "Error: chown command failed." >&2
    else
        echo "Success: Ownership changed to root."
    fi
else
    echo "Notice: Script is not running as root (UID is not 0)."
    echo "Skipping the 'chown' ownership change step gracefully."
fi
echo ""

echo "--- 4. Final Permissions ---"
NEW_SYM_PERMS=$(stat -c "%A" "$TARGET_FILE")
NEW_NUM_PERMS=$(stat -c "%a" "$TARGET_FILE")
echo "Updated permissions for '$TARGET_FILE':"
echo "  Symbolic: $NEW_SYM_PERMS"
echo "  Numeric:  $NEW_NUM_PERMS"

exit 0
