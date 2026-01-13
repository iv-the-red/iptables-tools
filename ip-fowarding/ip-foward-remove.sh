#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
  echo "Run as root."
  exit 1
fi

echo "Scanning DNAT rules (PREROUTING)..."
echo

iptables -t nat -L PREROUTING --line-numbers -n | grep DNAT || {
  echo "No DNAT rules found."
  exit 0
}

echo
read -rp "Enter PREROUTING rule number to remove (Usually they are two): " NUM

RULE=$(iptables -t nat -L PREROUTING -n --line-numbers | awk -v n="$NUM" '$1==n')

if [[ -z "$RULE" ]]; then
  echo "Invalid rule number."
  exit 1
fi

PROTO=$(echo "$RULE" | awk '{print $4}')
IN_PORT=$(echo "$RULE" | grep -oE 'dpt:[0-9]+' | cut -d: -f2)
DEST=$(echo "$RULE" | grep -oE 'to:[0-9\.]+:[0-9]+' | cut -d: -f2-)
DEST_IP=${DEST%:*}
DEST_PORT=${DEST##*:}

echo
echo "Removing:"
echo "  $PROTO $IN_PORT -> $DEST_IP:$DEST_PORT"
echo

# PREROUTING
iptables -t nat -D PREROUTING "$NUM"

# POSTROUTING
iptables -t nat -D POSTROUTING -p "$PROTO" -d "$DEST_IP" --dport "$DEST_PORT" -j MASQUERADE 2>/dev/null || true

# FORWARD rules
iptables -D FORWARD -p "$PROTO" -d "$DEST_IP" --dport "$DEST_PORT" -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -p "$PROTO" -s "$DEST_IP" --sport "$DEST_PORT" -j ACCEPT 2>/dev/null || true


# REMOVE other stuff thats left
# IF exists. IF NOT exists, ignore errors

echo
echo "Removing port forward (Additional):"
echo "${DEST_IP}:${DEST_PORT}"
echo
echo "IGNORE ERRORS IF RULES DO NOT EXIST"
echo

iptables -t nat -D POSTROUTING -p tcp -d "$DEST_IP" --dport "$DEST_PORT" -j MASQUERADE
iptables -t nat -D POSTROUTING -p udp -d "$DEST_IP" --dport "$DEST_PORT" -j MASQUERADE


echo "Removed."
echo "Starting second removal (If applicable)..."

iptables -t nat -L PREROUTING --line-numbers -n | grep DNAT || {
  echo "No DNAT rules found."
}

echo
read -rp "Enter PREROUTING rule number to remove (If there is none enter "-"): " NUM
if [[ "$NUM" == "-" ]]; then
  echo "No more rules to remove."
  exit 0
fi

RULE=$(iptables -t nat -L PREROUTING -n --line-numbers | awk -v n="$NUM" '$1==n')

if [[ -z "$RULE" ]]; then
  echo "Invalid rule number."
  exit 1
fi

PROTO=$(echo "$RULE" | awk '{print $4}')
IN_PORT=$(echo "$RULE" | grep -oE 'dpt:[0-9]+' | cut -d: -f2)
DEST=$(echo "$RULE" | grep -oE 'to:[0-9\.]+:[0-9]+' | cut -d: -f2-)
DEST_IP=${DEST%:*}
DEST_PORT=${DEST##*:}

echo
echo "Removing:"
echo "  $PROTO $IN_PORT -> $DEST_IP:$DEST_PORT"
echo

# PREROUTING
iptables -t nat -D PREROUTING "$NUM"

# POSTROUTING
iptables -t nat -D POSTROUTING -p "$PROTO" -d "$DEST_IP" --dport "$DEST_PORT" -j MASQUERADE 2>/dev/null || true

# FORWARD rules
iptables -D FORWARD -p "$PROTO" -d "$DEST_IP" --dport "$DEST_PORT" -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -p "$PROTO" -s "$DEST_IP" --sport "$DEST_PORT" -j ACCEPT 2>/dev/null || true


# REMOVE other stuff thats left
# IF exists. IF NOT exists, ignore errors

echo
echo "Removing port forward (Additional):"
echo "${DEST_IP}:${DEST_PORT}"
echo
echo "IGNORE ERRORS IF RULES DO NOT EXIST"
echo

iptables -t nat -D POSTROUTING -p tcp -d "$DEST_IP" --dport "$DEST_PORT" -j MASQUERADE
iptables -t nat -D POSTROUTING -p udp -d "$DEST_IP" --dport "$DEST_PORT" -j MASQUERADE


echo "Removed."
echo "Exiting."
exit 0