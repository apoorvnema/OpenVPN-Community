#!/bin/bash

# list-clients.sh - High Precision OpenVPN Dashboard
# Fixes: Table alignment, Active status matching, and History parsing.
# Update: Expanded REAL IP column to 25 spacing.

CONTAINER_NAME="openvpn"
NOW=$(date +%s)

# 1. Gather all data sources
PKI_INDEX=$(docker exec "$CONTAINER_NAME" cat /etc/openvpn/pki/index.txt 2>/dev/null)
STATUS_LOG=$(docker exec "$CONTAINER_NAME" cat /tmp/openvpn-status.log 2>/dev/null || docker exec "$CONTAINER_NAME" cat /etc/openvpn/openvpn-status.log 2>/dev/null)
HISTORY_LOG=$(docker logs "$CONTAINER_NAME" --tail 3000 2>&1 | grep -E "Peer Connection Initiated|client-instance exiting|Inactivity timeout")

if [ -z "$PKI_INDEX" ]; then
    echo -e "\033[31mError: Could not read PKI from container.\033[0m"
    exit 1
fi

# Prepare temp files for awk
echo "$PKI_INDEX" > /tmp/ovpn_pki
echo "$STATUS_LOG" > /tmp/ovpn_status
echo "$HISTORY_LOG" > /tmp/ovpn_history

awk -v now="$NOW" '
BEGIN {
    # Month map for manual date parsing
    m["Jan"]="01"; m["Feb"]="02"; m["Mar"]="03"; m["Apr"]="04"; m["May"]="05"; m["Jun"]="06"
    m["Jul"]="07"; m["Aug"]="08"; m["Sep"]="09"; m["Oct"]="10"; m["Nov"]="11"; m["Dec"]="12"
    
    print "\n\033[1;36m┌─────────────────────┬────────────┬────────────────────────────┬─────────────┬───────────────────────────┐"
    printf "│ %-19s │ %-10s │ %-26s │ %-11s │ %-25s │\n", "CLIENT NAME", "STATUS", "LAST/CURRENT LOGIN", "DURATION", "REAL IP"
    print "├─────────────────────┼────────────┼────────────────────────────┼─────────────┼───────────────────────────┤\033[0m"
}

# --- Helper to trim whitespace/newlines ---
function trim(s) {
    gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s)
    return s
}

# --- Helper to convert "Wed Mar 11 09:05:24 2026" to epoch ---
function to_epoch(str,   parts, date_str, result) {
    if (!str || str == "N/A") return 0
    split(str, parts, /[ :]+/)
    # parts: 1:Day, 2:Month, 3:DayNum, 4:HH, 5:MM, 6:SS, 7:YYYY
    date_str = sprintf("%s %s %s %s %s %s", parts[7], m[parts[2]], sprintf("%02d", parts[3]), parts[4], parts[5], parts[6])
    result = mktime(date_str)
    return (result > 0) ? result : 0
}

# --- PROCESS PKI (All valid certificates) ---
(FILENAME == "/tmp/ovpn_pki") && /^V/ {
    split($0, lp, "CN="); cn = trim(lp[2])
    if (!cn) { split($0,f,/[ \t]+/); split(f[NF],cnp,"="); cn=trim(cnp[2]) }
    if (cn) all_clients[cn] = 1
    next
}

# --- PROCESS STATUS LOG (Active sessions) ---
(FILENAME == "/tmp/ovpn_status") {
    if (/^CLIENT_LIST/) {
        split($0, s, ","); cn=trim(s[2]); ip=s[3]
        since=s[7]; epoch=s[8]
        # Locate epoch if shifted
        for(i=1; i<=NF; i++) { if ($i ~ /^[0-9]{10}$/) { epoch = $i; break } }
        active[cn]=1; login[cn]=since; ips[cn]=ip; durs[cn]=now-epoch
    } else if (NF >= 5 && $0 ~ /^[A-Za-z0-9_-]+,[0-9.]+:[0-9]+,[0-9]+,[0-9]+,/) {
        split($0, s, ","); cn=trim(s[1]); ip=s[2]; since=s[5]
        active[cn]=1; login[cn]=since; ips[cn]=ip; durs[cn]=now-to_epoch(since)
    }
    next
}

# --- PROCESS HISTORY LOG (Offline data) ---
(FILENAME == "/tmp/ovpn_history") {
    # Connection Start
    if (/Peer Connection Initiated/) {
        # Extract CN: [name]
        match($0, /\[[^\]]+\]/); 
        cn = trim(substr($0, RSTART+1, RLENGTH-2))
        
        # Extract Date: First 5-6 fields are standard
        dt = $1 " " $2 " " $3 " " $4 " " $5
        if (cn && !active[cn]) { 
            hist_login[cn] = dt; hist_epoch[cn] = to_epoch(dt) 
            # Extract Remote IP
            match($0, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+/);
            if (!RSTART) match($0, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/);
            hist_ips[cn] = substr($0, RSTART, RLENGTH)
        }
    }
    # Connection End
    if (/received, client-instance exiting|Inactivity timeout/) {
        # Format: Date ... CN/IP ...
        match($0, /[0-9A-Za-z_-]+\/[0-9]+\.[0-9]+/);
        slice = substr($0, RSTART, RLENGTH)
        split(slice, parts, "/"); cn = trim(parts[1])
        dt = $1 " " $2 " " $3 " " $4 " " $5
        if (cn && !active[cn] && hist_epoch[cn] > 0) {
            hist_dur[cn] = to_epoch(dt) - hist_epoch[cn]
        }
    }
    next
}

END {
    active_count = 0
    total_count = 0
    
    # Sort and Print
    for (cn in all_clients) {
        total_count++
        if (active[cn]) {
            active_count++
            d = durs[cn]
            dur_str = sprintf("%02dh %02dm %02ds", int(d/3600), int((d%3600)/60), d%60)
            printf "│ \033[1m%-19s\033[0m │ \033[32m%-10s\033[0m │ %-26s │ %-11s │ %-25s │\n", cn, "ACTIVE", login[cn], dur_str, ips[cn]
        } else {
            l = (hist_login[cn]) ? hist_login[cn] : "N/A"
            ip = (hist_ips[cn]) ? hist_ips[cn] : "---"
            d = hist_dur[cn]
            dur_str = (d > 0) ? sprintf("%02dh %02dm %02ds", int(d/3600), int((d%3600)/60), d%60) : "N/A"
            printf "│ %-19s │ \033[31m%-10s\033[0m │ %-26s │ %-11s │ %-25s │\n", cn, "OFFLINE", l, dur_str, ip
        }
    }
    print "\033[1;36m└─────────────────────┴────────────┴────────────────────────────┴─────────────┴───────────────────────────┘\033[0m"
    printf "  Summary: Total: %d | Active: \033[32m%d\033[0m | Offline: \033[31m%d\033[0m\n\n", total_count, active_count, total_count-active_count
}
' /tmp/ovpn_pki /tmp/ovpn_status /tmp/ovpn_history

rm /tmp/ovpn_pki /tmp/ovpn_status /tmp/ovpn_history
