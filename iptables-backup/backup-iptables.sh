#!/bin/bash

BACKUP_DIR="$HOME/iptables_backups"
mkdir -p "$BACKUP_DIR"

list_backups() {
    ls -1t "$BACKUP_DIR"/*.rules 2>/dev/null | head -n 20
}

create_backup() {
    FILE="$BACKUP_DIR/iptables-$(date +%F_%H-%M-%S).rules"
    iptables-save > "$FILE"
    echo "Backup saved: $FILE"
}

view_backup() {
    local FILE="$1"
    echo "==== Contents of $FILE ===="
    cat "$FILE"
    echo "==========================="
    echo
}

restore_backup() {
    local FILE="$1"
    read -p "Are you sure you want to restore $FILE? This will overwrite current iptables rules! [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        iptables-restore < "$FILE"
        echo "Rules restored from $FILE"
    else
        echo "Restore canceled."
    fi
}

# --- Main menu ---

while true; do
    echo "============================="
    echo "IPTables Backup Manager"
    echo "1) Create new backup"
    echo "2) View/Restore backups"
    echo "0) Exit"
    echo "============================="
    echo
    echo
    read -p "Select option: " MAIN_OPT

    case $MAIN_OPT in
        1)
            create_backup
            ;;
        2)
            while true; do
                echo "---- Last 20 backups ----"
                BACKUPS=($(list_backups))
                if [ ${#BACKUPS[@]} -eq 0 ]; then
                    echo "No backups found."
                    echo
                    break
                fi

                for i in "${!BACKUPS[@]}"; do
                    echo "$((i+1))) ${BACKUPS[$i]}"
                done
                echo "0) Back to main menu"
                echo

                read -p "Select backup to view/restore: " SEL
                if [ "$SEL" == "0" ]; then
                    break
                elif [[ "$SEL" =~ ^[0-9]+$ ]] && [ "$SEL" -ge 1 ] && [ "$SEL" -le "${#BACKUPS[@]}" ]; then
                    BACKUP_FILE="${BACKUPS[$((SEL-1))]}"
                    echo "1) View"
                    echo "2) Restore"
                    echo "0) Back"
                    echo
                    read -p "Choose action: " ACTION
                    case $ACTION in
                        1)
                            view_backup "$BACKUP_FILE"
                            ;;
                        2)
                            restore_backup "$BACKUP_FILE"
                            ;;
                        0)
                            ;;
                        *)
                            echo "Invalid action."
                            ;;
                    esac
                else
                    echo "Invalid selection."
                fi
            done
            ;;
        0)
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done
