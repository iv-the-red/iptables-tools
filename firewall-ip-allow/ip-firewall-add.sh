#!/bin/bash

INSERT_POS=1

read -p "Enter port numbers (comma separated): " PORTS
[ -z "$PORTS" ] && echo "No ports entered." && exit 1

read -p "Protocol (tcp/udp/both) [both]: " PROTO
PROTO=${PROTO:-both}

IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

for PORT in "${PORT_ARRAY[@]}"; do
    PORT=$(echo "$PORT" | xargs) # trim spaces

    case "$PROTO" in
        tcp)
            iptables -I INPUT $INSERT_POS -p tcp --dport "$PORT" -m conntrack --ctstate NEW -j ACCEPT
            ;;
        udp)
            iptables -I INPUT $INSERT_POS -p udp --dport "$PORT" -j ACCEPT
            ;;
        both)
            iptables -I INPUT $INSERT_POS -p tcp --dport "$PORT" -m conntrack --ctstate NEW -j ACCEPT
            iptables -I INPUT $INSERT_POS -p udp --dport "$PORT" -j ACCEPT
            ;;
        *)
            echo "Invalid protocol."
            exit 1
            ;;
    esac

    echo "Port $PORT/$PROTO allowed"
done
