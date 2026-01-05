# IP Forwarding Helpers

Small bash helpers to add or remove simple destination NAT port-forwarding rules with iptables (IPv4).

## Prerequisites
- Linux host with `iptables` available and `nat` table enabled.
- Root privileges (scripts exit if not run as root).
- Target host reachable from this machine.

> [!WARNING]   
> **Make sure you have ip fowarding enabled:**
```bash
sysctl -w net.ipv4.ip_forward=1
```

## What the scripts do
- `ip-add.sh` adds DNAT + MASQUERADE rules for both TCP and UDP, and permits forwarding for the chosen destination.
- `ip-remove.sh` lists DNAT rules with line numbers and removes the selected PREROUTING rule plus the matching POSTROUTING and FORWARD entries.

## Usage
1) Add a forward
```bash
sudo ./ip-add.sh
```
You will be prompted for:
- Incoming port (public)
- Destination IP
- Destination port

2) Remove a forward
```bash
sudo ./ip-remove.sh
```
- The script shows DNAT rules in PREROUTING and asks for the rule number to delete (you may need to repeat for both TCP/UDP entries).
- It derives protocol, ports, and destination from that line and removes associated NAT and FORWARD rules.

## Notes
- Rules created here are ephemeral; persist them with your preferred method (e.g., `iptables-save`/`iptables-restore` or your distro's firewall service).
- Be careful when deleting: choose the correct line number shown in the PREROUTING list.
- Scripts use `set -e`, so they stop on errors (except some cleanup deletions which ignore missing rules).
