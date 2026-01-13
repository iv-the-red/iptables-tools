# iptables-tools

Small bash helpers around `iptables` for common tasks:

- Open or close ports on the INPUT chain.
- Add or remove simple destination NAT port-forwarding rules.
- Create, list, view, and restore iptables backups.

## Layout

- `firewall-ip-allow/`
	- `ip-firewall-add.sh` – allow one or more ports on INPUT.
	- `ip-firewall-remove.sh` – remove rules that match a given port.
- `ip-fowarding/`
	- `ip-foward-add.sh` – add IPv4 DNAT + MASQUERADE port forward.
	- `ip-foward-remove.sh` – remove an existing port forward.
- `iptables-backup/`
	- `backup-iptables.sh` – simple TUI for iptables backups.

## Prerequisites

- Linux host with `iptables` available and the `nat` table enabled.
- Root privileges (most scripts exit if not run as root).
- For port forwarding, the destination host must be reachable from this machine.

> [!WARNING]
> For DNAT port forwarding you must enable IPv4 forwarding:
>
> ```bash
> sudo sysctl -w net.ipv4.ip_forward=1
> ```

---

## firewall-ip-allow – open/close ports on INPUT

Directory: `firewall-ip-allow/`

### ip-firewall-add.sh

Interactively inserts INPUT rules to allow one or more ports.

```bash
cd firewall-ip-allow
sudo ./ip-firewall-add.sh
```

You will be prompted for:

- Port numbers (comma separated), e.g. `80,443, 8080`.
- Protocol: `tcp`, `udp`, or `both` (default is `both`).

For each port, the script inserts rules near the top of INPUT, using `-m conntrack --ctstate NEW` for TCP to only allow new connections.

### ip-firewall-remove.sh

Removes any rules that reference a given port, based on `iptables-save` output.

```bash
cd firewall-ip-allow
sudo ./ip-firewall-remove.sh
```

You will be prompted for a single port number. All matching rules containing that port are translated from `-A ...` to `iptables -D ...` and deleted.

---

## ip-fowarding – simple DNAT port forwarding

Directory: `ip-fowarding/` (IPv4 only).

These helpers configure destination NAT (DNAT) with MASQUERADE and the necessary FORWARD rules for a single external port mapped to a host/port behind this machine.

### ip-foward-add.sh

```bash
cd ip-fowarding
sudo ./ip-foward-add.sh
```

Prompts for:

- Incoming port (public).
- Destination IP (internal/target host).
- Destination port.

For both TCP and UDP it will:

- Add a `PREROUTING` rule in the `nat` table with DNAT.
- Add a `POSTROUTING` `MASQUERADE` rule in the `nat` table.
- Add matching `FORWARD` rules (NEW/ESTABLISHED/RELATED flows in both directions).

### ip-foward-remove.sh

```bash
cd ip-fowarding
sudo ./ip-foward-remove.sh
```

The script:

- Lists `PREROUTING` DNAT rules (with line numbers).
- Asks for the rule number to remove (usually twice – once for TCP and once for UDP).
- Derives protocol, ports, and destination from that rule.
- Deletes the selected `PREROUTING` line plus related `POSTROUTING` MASQUERADE and `FORWARD` rules.
- Performs some additional cleanup deletions and ignores errors if rules are already gone.

Rules created by `ip-foward-add.sh` are ephemeral; they are lost on reboot unless saved.

---

## iptables-backup – backup and restore rules

Directory: `iptables-backup/`

`backup-iptables.sh` is a small interactive helper to manage rule snapshots under `$HOME/iptables_backups`.

```bash
cd iptables-backup
sudo ./backup-iptables.sh
```

Main menu:

- `1) Create new backup` – runs `iptables-save` and writes a timestamped `*.rules` file.
- `2) View/Restore backups` – lists the latest backups (up to 20), lets you:
	- View contents of a selected file.
	- Restore from a backup via `iptables-restore` (with confirmation prompt).
- `0) Exit` – quit the tool.

Restoring a backup **overwrites your current iptables ruleset**, so double-check the file you pick.

---

## General notes

- All changes are made directly with `iptables`; they are not persisted unless you save them separately (e.g. with `iptables-save`/`iptables-restore` or your distro's firewall tooling).
- Run these scripts via `sudo` or as root; otherwise some operations will fail.
- Always test from a remote shell you can recover from (e.g. a second SSH session) when modifying firewall rules, to avoid locking yourself out.
