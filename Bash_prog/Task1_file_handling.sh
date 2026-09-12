#!/usr/bin/env bash
# -------------------------------------------------------------------------
# @title       Task1_file_handling.sh
# @author      Emmanuel Gregory Opoku Owusu-Afriyie
# @index       4195524
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Creates a directory, manages files inside it, and handles errors
# @date        $(date +%Y-%m-%d)
# -------------------------------------------------------------------------

# 1. USAGE GUIDE & INPUT VALIDATION
# Check if exactly one argument (the target directory) is provided
if [ "$#" -ne 1 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Usage: $0 <target-directory>"
    echo "  <target-directory>  The folder where files will be created and managed"
    exit 1
fi

TARGET_DIR="$1"
TEST_FILE="${TARGET_DIR}/test_document.txt"
BAK_FILE="${TARGET_DIR}/test_document.bak"

# 2. DIRECTORY CREATION (Task Requirement 1)
# Check if it exists before trying to create it so we can report accurately
if [ -d "$TARGET_DIR" ]; then
    echo "Directory '$TARGET_DIR' already exists."
else
    echo "Creating directory '$TARGET_DIR'..."
    mkdir -p "$TARGET_DIR"
    
    # ERROR HANDLING: Stop immediately if creation fails (e.g., permission denied)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create directory '$TARGET_DIR'." >&2
        exit 1
    fi
    echo "Success: Directory created."
fi

# 3. CREATE & WRITE TO FILE (Task Requirement 2)
echo "Creating file and writing initial content..."
# Using > overwrites any existing content with the new text
echo "This is the first line of text." > "$TEST_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed to write to '$TEST_FILE'." >&2
    exit 1
fi
echo "Success: File created."

# 4. APPEND CONTENT (Task Requirement 3)
echo "Appending additional content..."
# Using >> appends text to the end of the file without deleting the old text
echo "This is the second appended line." >> "$TEST_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed to append to '$TEST_FILE'." >&2
    exit 1
fi
echo "Success: Content appended."

# 5. READ & DISPLAY CONTENT (Task Requirement 4)
echo "--- Contents of $TEST_FILE ---"
cat "$TEST_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed to read '$TEST_FILE'." >&2
    exit 1
fi
echo "--------------------------------"

# 6. COPY TO .BAK VERSION (Task Requirement 5)
echo "Creating backup copy (.bak)..."
cp "$TEST_FILE" "$BAK_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create backup file." >&2
    exit 1
fi
echo "Success: Backup created at '$BAK_FILE'."

# 7. DELETE ORIGINAL AFTER CHECKING (Task Requirement 6)
echo "Checking for original file before deletion..."
# The -f flag checks if a file exists and is a regular file
if [ -f "$TEST_FILE" ]; then
    echo "Confirmed: '$TEST_FILE' exists. Deleting now..."
    rm "$TEST_FILE"
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to delete '$TEST_FILE'." >&2
        exit 1
    fi
    echo "Success: Original file deleted. Backup remains."
else
    echo "Error: Cannot delete. '$TEST_FILE' does not exist." >&2
    exit 1
fi

# Exit successfully
exit 0
