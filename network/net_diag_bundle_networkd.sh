#!/usr/bin/env bash
# net_diag_bundle_networkd.sh
#
# Diagnostics for Ubuntu on Raspberry Pi when using systemd-networkd + systemd-resolved.
#
# Usage:
#   chmod +x net_diag_bundle_networkd.sh
#   sudo ./net_diag_bundle_networkd.sh
#   sudo IFACE=eth0 CAPTURE_SECONDS=45 ./net_diag_bundle_networkd.sh
#
# written by ELM ChaptGPT5.2 9/1/2026
# for use on rpis / linux systems running systemd-networkd

set -u  # keep going even if something fails; do NOT set -e

CAPTURE_SECONDS="${CAPTURE_SECONDS:-0}"   # 0 disables tcpdump capture
OUT_BASE="${OUT_BASE:-/tmp}"
IFACE="${IFACE:-eth0}"

ts="$(date -u +%Y%m%dT%H%M%SZ)"
host="$(hostname -s 2>/dev/null || hostname)"
outdir="${OUT_BASE%/}/netdiag-${host}-${ts}"
mkdir -p "$outdir"

summary="$outdir/summary.txt"

log() { printf '%s\n' "$*" | tee -a "$summary" >/dev/null; }
run() { local file="$1"; shift; { echo ">>> $*"; "$@"; echo; } >>"$file" 2>&1; }

# If IFACE doesn't exist, fall back to default-route iface
if ! ip link show dev "$IFACE" >/dev/null 2>&1; then
  IFACE="$(ip route 2>/dev/null | awk '/^default /{print $5; exit}')"
  IFACE="${IFACE:-eth0}"
fi

GW="$(ip route 2>/dev/null | awk '/^default /{print $3; exit}')"
IP4="$(ip -4 -o addr show dev "$IFACE" 2>/dev/null | awk '{print $4}' | head -n1)"

{
  echo "=== net_diag_bundle (systemd-networkd) ==="
  echo "UTC time: $(date -u --iso-8601=seconds 2>/dev/null || date -u)"
  echo "Host: $host"
  echo "Iface: $IFACE"
  echo "IPv4 on iface: ${IP4:-<none>}"
  echo "Gateway: ${GW:-<none>}"
  echo
} > "$summary"

# Core state
run "$outdir/state.txt" uname -a
run "$outdir/state.txt" uptime
run "$outdir/state.txt" ip -br link
run "$outdir/state.txt" ip -br addr
run "$outdir/state.txt" ip route
run "$outdir/state.txt" ip -6 route
run "$outdir/state.txt" ip neigh show
run "$outdir/state.txt" ip -d link show dev "$IFACE"
run "$outdir/state.txt" ip addr show dev "$IFACE"
run "$outdir/state.txt" ip neigh show dev "$IFACE"

if [[ -e "/sys/class/net/$IFACE/address" ]]; then
  echo "MAC ($IFACE): $(cat "/sys/class/net/$IFACE/address" 2>/dev/null || true)" >> "$outdir/state.txt"
  echo >> "$outdir/state.txt"
fi

# systemd-networkd view
run "$outdir/networkctl.txt" networkctl list
run "$outdir/networkctl.txt" networkctl status
run "$outdir/networkctl.txt" networkctl status "$IFACE"

# systemd-resolved view
if command -v resolvectl >/dev/null 2>&1; then
  run "$outdir/resolved.txt" resolvectl status
  run "$outdir/resolved.txt" resolvectl dns
  run "$outdir/resolved.txt" resolvectl domain
fi
if [[ -f /etc/resolv.conf ]]; then
  {
    echo ">>> /etc/resolv.conf"
    sed -n '1,200p' /etc/resolv.conf 2>/dev/null || true
    echo
  } >> "$outdir/resolved.txt"
fi

# Connectivity tests
log "=== CONNECTIVITY TESTS ==="

if [[ -n "${GW:-}" ]]; then
  log "[1] ping gateway ($GW)"
  ping -c 3 -W 1 "$GW" >>"$summary" 2>&1 || log "  -> ping gateway: FAILED"

  if command -v arping >/dev/null 2>&1; then
    log "[2] arping gateway ($GW)"
    arping -c 3 -w 3 -I "$IFACE" "$GW" >>"$summary" 2>&1 || log "  -> arping gateway: FAILED"
  else
    log "[2] arping not installed (optional)."
  fi
else
  log "[1] No default gateway found."
fi

log "[3] ping internet IP (8.8.8.8)"
ping -c 3 -W 1 8.8.8.8 >>"$summary" 2>&1 || log "  -> ping 8.8.8.8: FAILED"

log "[4] DNS resolve app.practable.io"
getent hosts app.practable.io >>"$summary" 2>&1 || log "  -> DNS resolve: FAILED"

log "[5] curl status endpoint"
curl -m 8 -sS -I "https://app.practable.io/ed0/access/status" >>"$summary" 2>&1 || log "  -> curl: FAILED"

# Renew attempt
log "=== RENEW ATTEMPT ==="
log "[6] bounce link $IFACE (down/up)"
ip link set dev "$IFACE" down >>"$summary" 2>&1 || true
sleep 2
ip link set dev "$IFACE" up >>"$summary" 2>&1 || true
sleep 2

if command -v dhclient >/dev/null 2>&1; then
  log "[7] dhclient probe (release/renew) on $IFACE"
  dhclient -r -v "$IFACE" >>"$summary" 2>&1 || true
  dhclient -v "$IFACE" >>"$summary" 2>&1 || true
fi

# Optional capture
if [[ "$CAPTURE_SECONDS" =~ ^[0-9]+$ ]] && (( CAPTURE_SECONDS > 0 )); then
  if command -v tcpdump >/dev/null 2>&1; then
    log "=== PACKET CAPTURE (DHCP+ARP) for ${CAPTURE_SECONDS}s ==="
    log "Capturing to: $outdir/dhcp_arp.pcap"
    timeout "$CAPTURE_SECONDS" tcpdump -ni "$IFACE" -vvv '(arp or (port 67 or port 68))' -w "$outdir/dhcp_arp.pcap" \
      >>"$summary" 2>&1 || true
  else
    log "tcpdump not installed; skipping capture."
  fi
else
  log "=== PACKET CAPTURE disabled (set CAPTURE_SECONDS=45 to enable) ==="
fi

# Journals
run "$outdir/journal_networkd.txt" journalctl -u systemd-networkd -n 400 --no-pager
run "$outdir/journal_resolved.txt" journalctl -u systemd-resolved -n 200 --no-pager
run "$outdir/journal_tail.txt" journalctl -n 200 --no-pager

# Heuristic hint
log ""
log "=== LIKELY PROBLEM (heuristic) ==="

GW2="$(ip route 2>/dev/null | awk '/^default /{print $3; exit}')"
IP4_2="$(ip -4 -o addr show dev "$IFACE" 2>/dev/null | awk '{print $4}' | head -n1)"

if [[ -z "${IP4_2:-}" ]]; then
  log "Hint: No IPv4 address on $IFACE -> DHCP/registration issue likely."
elif [[ -z "${GW2:-}" ]]; then
  log "Hint: Have IPv4 but no default route -> DHCP options or networkd config issue."
else
  if ping -c 1 -W 1 "$GW2" >/dev/null 2>&1; then
    if getent hosts app.practable.io >/dev/null 2>&1; then
      log "Hint: Gateway+DNS look OK now. If relay still missing, check app/service layer."
    else
      log "Hint: Gateway OK but DNS failing -> DNS/DHCP option issue."
    fi
  else
    log "Hint: Have IPv4+GW but cannot ping gateway -> ARP/L2 enforcement (DAI/IPSG), VLAN, or switch port issue likely."
  fi
fi

log ""
log "DONE. Bundle written to: $outdir"
log "To tar it, run:"
log "  cd ${OUT_BASE%/} && sudo tar -czf netdiag-${host}-${ts}.tgz netdiag-${host}-${ts}"
