#!/usr/bin/env bash
# check_netdiag_prereqs_networkd.sh
#
# Prerequisite checker for the *systemd-networkd* version of the diagnostics.
# (Does NOT require NetworkManager / nmcli.)
#
# Usage:
#   chmod +x check_netdiag_prereqs_networkd.sh
#   ./check_netdiag_prereqs_networkd.sh
#
# written by ELM ChaptGPT5.2 9/1/2026
# for use on rpis / linux systems running systemd-networkd
set -u

need_cmds=(
  bash
  ip
  ping
  awk
  sed
  cat
  find
  ls
  timeout
  journalctl
  networkctl
)

optional_cmds=(
  resolvectl
  curl
  tcpdump
  arping
  dhclient
)

pkg_hint() {
  case "$1" in
    ip) echo "iproute2" ;;
    ping) echo "iputils-ping" ;;
    journalctl|systemctl|networkctl) echo "systemd" ;;
    resolvectl) echo "systemd-resolved" ;;
    curl) echo "curl" ;;
    tcpdump) echo "tcpdump" ;;
    arping) echo "arping" ;;
    dhclient) echo "isc-dhcp-client" ;;
    timeout) echo "coreutils" ;;
    awk) echo "gawk" ;;
    sed) echo "sed" ;;
    find) echo "findutils" ;;
    ls|cat|bash) echo "coreutils/bash" ;;
    *) echo "" ;;
  esac
}

have() { command -v "$1" >/dev/null 2>&1; }

echo "== net_diag_bundle prerequisites check (systemd-networkd) =="
echo "Host: $(hostname 2>/dev/null || true)"
echo "UTC:  $(date -u 2>/dev/null || true)"
echo

missing_need=()
missing_opt=()

echo "-- Required commands --"
for c in "${need_cmds[@]}"; do
  if have "$c"; then
    printf "OK   %-12s -> %s\n" "$c" "$(command -v "$c")"
  else
    printf "MISS %-12s (pkg hint: %s)\n" "$c" "$(pkg_hint "$c")"
    missing_need+=("$c")
  fi
done

echo
echo "-- Optional commands (recommended) --"
for c in "${optional_cmds[@]}"; do
  if have "$c"; then
    printf "OK   %-12s -> %s\n" "$c" "$(command -v "$c")"
  else
    printf "MISS %-12s (pkg hint: %s)\n" "$c" "$(pkg_hint "$c")"
    missing_opt+=("$c")
  fi
done

echo
echo "-- Service state (context) --"
if command -v systemctl >/dev/null 2>&1; then
  systemctl is-active systemd-networkd 2>/dev/null | sed "s/^/systemd-networkd: /" || true
  systemctl is-active systemd-resolved 2>/dev/null | sed "s/^/systemd-resolved: /" || true
  systemctl is-active NetworkManager 2>/dev/null | sed "s/^/NetworkManager: /" || true
else
  echo "systemctl not found"
fi

echo
if ((${#missing_need[@]})); then
  echo "RESULT: Missing REQUIRED commands: ${missing_need[*]}"
  pkgs=()
  for c in "${missing_need[@]}"; do
    p="$(pkg_hint "$c")"
    [[ -n "$p" ]] && pkgs+=("$p")
  done
  if ((${#pkgs[@]})); then
    echo
    echo "Install (example):"
    echo "  sudo apt-get update && sudo apt-get install -y ${pkgs[*]}"
  else
    echo "No package hints available for some missing items."
  fi
  exit 1
else
  echo "RESULT: All REQUIRED commands present."
  if ((${#missing_opt[@]})); then
    echo "Optional missing: ${missing_opt[*]}"
    pkgs=()
    for c in "${missing_opt[@]}"; do
      p="$(pkg_hint "$c")"
      [[ -n "$p" ]] && pkgs+=("$p")
    done
    if ((${#pkgs[@]})); then
      echo
      echo "Recommended install (example):"
      echo "  sudo apt-get update && sudo apt-get install -y ${pkgs[*]}"
    fi
  fi
fi
