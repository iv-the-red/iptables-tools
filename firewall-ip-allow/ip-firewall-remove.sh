#!/bin/bash

# Ask for port
read -p "Enter port number to remove: " PORT
if [[ -z "$PORT" ]]; then
    echo "No port entered. Exiting."
    exit 1
fi

# Remove matching rules
iptables-save | grep "$PORT" | while read -r line; do
    # Convert to delete command
    RULE=$(echo "$line" | sed 's/-A/iptables -D/')
    eval "$RULE"
done

echo "All rules for port $PORT removed."
