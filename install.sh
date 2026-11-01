#!/usr/bin/env bash
# Hashem one-line installer — resilient multi-mirror download & auto-setup.
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/roboapi2/didi-tunnel/main/install.sh)
set -euo pipefail
# Build the Community panel from the standalone Didi Tunnel main branch.
export HASHEM_SOURCE_REF="${HASHEM_SOURCE_REF:-main}"

if [[ $EUID -ne 0 ]]; then
    echo "Error: Please run as root (sudo)." >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Display HASHEM logo banner
clear 2>/dev/null || true
echo -e "\033[0;36m"
printf "  DIDI TUNNEL\n"
echo -e "\033[0m"
echo -e "\033[0;36m==============================================================\033[0m"
echo -e "\033[1;32m     DIDI TUNNEL COMMUNITY INSTALLER\033[0m"
echo -e "\033[0;36m==============================================================\033[0m"
echo -e "\033[0;33m[*] Downloading core manager script...\033[0m"

# Mirrors are third parties: a script from a mirror is only trusted when the
# canonical GitHub copy was reachable, or when two different mirror hosts
# served byte-identical content. HASHEM_SHA256=<hex> pins the exact script;
# HASHEM_ALLOW_UNVERIFIED=1 is the explicit (unsafe) opt-out.
PRIMARY="https://raw.githubusercontent.com/roboapi2/didi-tunnel/${HASHEM_SOURCE_REF:-main}/hashem.sh"
if [[ -n "${HASHEM_INSTALL_URLS:-}" ]]; then
    read -r -a URLS <<< "$HASHEM_INSTALL_URLS"   # test/override hook
    PRIMARY="${URLS[0]}"
else
    URLS=(
        "$PRIMARY"
        "https://mirror.ghproxy.com/$PRIMARY"
        "https://ghproxy.net/$PRIMARY"
        "https://fastly.jsdelivr.net/gh/roboapi2/didi-tunnel@${HASHEM_SOURCE_REF:-main}/hashem.sh"
    )
fi

url_host() { local h="${1#*://}"; echo "${h%%/*}"; }

# fetch_verified <outfile>: 0 when a trustworthy copy is in <outfile>.
fetch_verified() {
    local out="$1" i=0 U f sum host
    local -A seen_hosts=() seen_sum=()
    for U in "${URLS[@]}"; do
        i=$((i + 1)); f="$TMP/cand.$i"
        curl -fsSL --connect-timeout 8 --max-time 40 "$U" -o "$f" 2>/dev/null && [[ -s "$f" ]] && bash -n "$f" 2>/dev/null || continue
        sum=$(sha256sum "$f" | awk '{print $1}')
        host=$(url_host "$U")
        if [[ -n "${HASHEM_SHA256:-}" ]]; then
            if [[ "${HASHEM_SHA256,,}" == "$sum" ]]; then cp "$f" "$out"; echo "$sum"; return 0; fi
            echo "[!] $host served a script that does not match HASHEM_SHA256 (got $sum)" >&2
            continue
        fi
        if [[ "$U" == "$PRIMARY" ]]; then cp "$f" "$out"; echo "$sum"; return 0; fi
        # mirror: need a second, different host with the same hash
        if [[ -n "${seen_sum[$sum]:-}" && "${seen_sum[$sum]}" != "$host" ]]; then
            cp "$f" "$out"; echo "$sum"; return 0
        fi
        seen_sum[$sum]="$host"; seen_hosts[$host]=1
        if [[ "${HASHEM_ALLOW_UNVERIFIED:-0}" == "1" ]]; then
            cp "$f" "$out"; echo "$sum"; return 0
        fi
    done
    return 1
}

if ! SCRIPT_SHA=$(fetch_verified "$TMP/hashem.sh"); then
    echo "Error: could not obtain a verified hashem.sh." >&2
    echo "       GitHub was unreachable and no two mirrors agreed. Retry later," >&2
    echo "       pin a known hash with HASHEM_SHA256=<sha256>, or (unsafe) set HASHEM_ALLOW_UNVERIFIED=1." >&2
    exit 1
fi
echo -e "\033[0;33m[*] hashem.sh sha256: ${SCRIPT_SHA}\033[0m"

chmod +x "$TMP/hashem.sh"
mkdir -p /usr/local/bin
cp "$TMP/hashem.sh" /usr/local/bin/hashem.sh
cp "$TMP/hashem.sh" /usr/local/bin/hashem
chmod +x /usr/local/bin/hashem.sh /usr/local/bin/hashem
ln -sf /usr/local/bin/hashem.sh /usr/local/bin/gre.sh 2>/dev/null || true

bash /usr/local/bin/hashem "$@"

echo -e "\033[1;32mDidi Tunnel - based on Hashem Panel\033[0m"
echo ""

