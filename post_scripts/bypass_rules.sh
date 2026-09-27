#!/bin/bash
# =====================================================================
# АВТОМАТИЧЕСКИЙ ОБХОД VPN ДЛЯ РОССИИ И БЕЛАРУСИ (IPDENY AGGREGATED)
# =====================================================================
BYPASS_IFACE=$(ip route | awk '/default.+veth/ {print $5}') # Родный интерфейс контейнера
BYPASS_GW=$(ip route | awk '/default.+veth/ {print $3}') # Родный шлюз контейнера, который пускает траффик напрямую, без туннеля
COUNTRIES="ru by"
COMPANY_ASNS="15169 13238 8075 36459 31898"
# 15169 - Google
# 13238 - Yandex
# 8075  - Microsoft
# 36459 - GitHub
# 31898 - Red Hat (includes Ansible)

if [ -n "$BYPASS_GW" ]; then
    echo "Applying direct routes for countries via gateway ($BYPASS_GW)..."
    for country in $COUNTRIES; do
        echo "Downloading zones for ${country}..."
        for subnet in $(wget -qO- "https://www.ipdeny.com/ipblocks/data/aggregated/${country}-aggregated.zone" 2>/dev/null); do
            ip route replace "$subnet" via "$BYPASS_GW" dev "$BYPASS_IFACE" || true
        done
    done
    echo "Country bypass routes applied successfully!"

    for asn in $COMPANY_ASNS; do
        echo "Downloading IP ranges for ASN ${asn}..."
        for subnet in $(wget -qO- "https://raw.githubusercontent.com/ipverse/asn-ip-blocks/master/as${asn}/ipv4-aggregated.txt" 2>/dev/null); do
            ip route replace "$subnet" via "$BYPASS_GW" dev "$BYPASS_IFACE" || true
        done
    done
    echo "Corporate bypass routes applied successfully!"
else
    echo "ERROR: Could not find virt gateway for bypass routing!"
fi
