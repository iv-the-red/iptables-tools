#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
  echo "Run as root."
  exit 1
fi

read -rp "Incoming port (public): " IN_PORT
read -rp "Destination IP: " DEST_IP
read -rp "Destination port: " DEST_PORT

echo
echo "Adding port forward:"
echo "  ${IN_PORT}  ->  ${DEST_IP}:${DEST_PORT}"
echo

for PROTO in tcp udp; do
  iptables -t nat -A PREROUTING -p $PROTO --dport "$IN_PORT" \
    -j DNAT --to-destination "$DEST_IP:$DEST_PORT"

  iptables -t nat -A POSTROUTING -p $PROTO -d "$DEST_IP" --dport "$DEST_PORT" \
    -j MASQUERADE

  iptables -A FORWARD -p $PROTO -d "$DEST_IP" --dport "$DEST_PORT" \
    -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT

  iptables -A FORWARD -p $PROTO -s "$DEST_IP" --sport "$DEST_PORT" \
    -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
done

echo "Done."