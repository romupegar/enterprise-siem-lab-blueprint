#!/usr/bin/env bash
# ==============================================================================
# Script: baseline_audit.sh
# Description: Non-intrusive health, storage mount, and security service check
# ==============================================================================

set -euo pipefail

echo "=== NODE BASELINE AUDIT ($(date -u +"%Y-%m-%dT%H:%M:%SZ")) ==="

echo -e "\n[+] Storage & NAS Mount Verification:"
df -hT -x tmpfs -x devtmpfs | awk 'NR==1 || /nfs|zfs|ext4|xfs/'

echo -e "\n[+] Security & Overlay Daemons:"
for daemon in wazuh-agent crowdsec fail2ban tailscaled ssh; do
    if systemctl is-active --quiet "$daemon" 2>/dev/null; then
        echo "  [ACTIVE]   $daemon"
    else
        echo "  [INACTIVE] $daemon"
    fi
done

echo -e "\n[+] Firewall Status:"
if command -v ufw &> /dev/null; then
    ufw status | head -n 1
elif command -v nft &> /dev/null; then
    echo "  nftables ruleset loaded ($(nft list ruleset | wc -l) lines)"
fi
