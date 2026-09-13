
#!/usr/bin/env bash
# -------------------------------------------------------------------------
# @title       Task5_crud_app.sh
# @author      Emmanuel Gregory Opoku Owusu-Afriyie
# @index       4195524
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Menu-driven CRUD console application (Phonebook)
# @date        $(date +%Y-%m-%d)
# -------------------------------------------------------------------------

# 1. USAGE GUIDE
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Usage: ./Task5_crud_app.sh"
    echo "  This is an interactive Phonebook CRUD application."
    echo "  It takes no arguments and runs entirely through a terminal menu."
    exit 0
fi

DB_FILE="phonebook_data.csv"
BAK_FILE="phonebook_data.csv.bak"

# Initialize the database file if it doesn't exist
if [ ! -f "$DB_FILE" ]; then
    touch "$DB_FILE"
fi

# --- HELPER FUNCTIONS ---

backup_data() {
    cp "$DB_FILE" "$BAK_FILE"
    echo "[System] Backup created at $BAK_FILE"
}

# --- CRUD FUNCTIONS ---

add_record() {
    echo -e "\n--- Add New Contact ---"
    local id=$(date +%s)
    
    echo -n "Enter Name: "
    read name
    echo -n "Enter Phone: "
    read phone
    echo -n "Enter Email: "
    read email

    # Input validation
    if [ -z "$name" ] || [ -z "$phone" ] || [ -z "$email" ]; then
        echo "Error: All fields are required. Contact not added." >&2
        return
    fi

    echo "$id,$name,$phone,$email" >> "$DB_FILE"
    echo "Success: Contact '$name' added with ID $id."
}

view_records() {
    echo -e "\n--- Phonebook Directory ---"
    if [ ! -s "$DB_FILE" ]; then
        echo "The phonebook is currently empty."
        return
    fi
    
    printf "%-15s | %-20s | %-15s | %-25s\n" "ID" "NAME" "PHONE" "EMAIL"
    echo "--------------------------------------------------------------------------------"
    while IFS=',' read -r id name phone email; do
        printf "%-15s | %-20s | %-15s | %-25s\n" "$id" "$name" "$phone" "$email"
    done < "$DB_FILE"
}

search_record() {
    echo -e "\n--- Search Contacts ---"
    echo -n "Enter search term (Name, Phone, or Email): "
    read term
    
    if [ -z "$term" ]; then
        echo "Error: Search term cannot be empty." >&2
        return
    fi

    echo "Search Results:"
    local results=$(grep -i "$term" "$DB_FILE")
    
    if [ -z "$results" ]; then
        echo "No records found matching '$term'."
    else
        echo "$results" | while IFS=',' read -r id name phone email; do
            echo "- ID: $id | Name: $name | Phone: $phone | Email: $email"
        done
    fi
}

update_record() {
    echo -e "\n--- Update Contact ---"
    echo -n "Enter the ID of the contact to update: "
    read target_id
    
    local record=$(grep "^$target_id," "$DB_FILE")
    if [ -z "$record" ]; then
        echo "Error: Record with ID '$target_id' not found." >&2
        return
    fi

    echo "Found Record: $record"
    echo "Please enter new details:"
    
    echo -n "New Name: "
    read name
    echo -n "New Phone: "
    read phone
    echo -n "New Email: "
    read email

    if [ -z "$name" ] || [ -z "$phone" ] || [ -z "$email" ]; then
        echo "Error: Fields cannot be empty. Update cancelled." >&2
        return
    fi

    backup_data
    
    grep -v "^$target_id," "$DB_FILE" > temp.csv
    echo "$target_id,$name,$phone,$email" >> temp.csv
    mv temp.csv "$DB_FILE"
    
    echo "Success: Contact ID $target_id has been updated."
}

delete_record() {
    echo -e "\n--- Delete Contact ---"
    echo -n "Enter the ID of the contact to delete: "
    read target_id
    
    local record=$(grep "^$target_id," "$DB_FILE")
    if [ -z "$record" ]; then
        echo "Error: Record with ID '$target_id' not found." >&2
        return
    fi

    echo "Found Record: $record"
    echo -n "Are you absolutely sure you want to delete this contact? (y/n): "
    read confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        backup_data
        grep -v "^$target_id," "$DB_FILE" > temp.csv
        mv temp.csv "$DB_FILE"
        echo "Success: Contact ID $target_id deleted."
    else
        echo "Deletion cancelled."
    fi
}

# --- MAIN MENU LOOP ---

while true; do
    echo -e "\n============================="
    echo "     PHONEBOOK CRUD APP"
    echo "============================="
    echo "1. Add Contact"
    echo "2. View All Contacts"
    echo "3. Search Contacts"
    echo "4. Update Contact"
    echo "5. Delete Contact"
    echo "6. Exit"
    echo "============================="
    echo -n "Select an option (1-6): "
    read choice

    case $choice in
        1) add_record ;;
        2) view_records ;;
        3) search_record ;;
        4) update_record ;;
        5) delete_record ;;
        6) 
            echo "Exiting application. Goodbye!"
            exit 0 
            ;;
        *) 
            echo "Invalid option. Please enter a number between 1 and 6." >&2 
            ;;
    esac
done
