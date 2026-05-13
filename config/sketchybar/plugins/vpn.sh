#!/usr/bin/env bash
# VPN indicator. ProtonVPN (and most modern macOS VPN clients) tunnel via
# utun interfaces — when one has an IPv4 address, the VPN is up. This
# detection is generic to any tunnel-based VPN, not Proton-specific.

VPN_ACTIVE=0
for iface in $(ifconfig -l | tr ' ' '\n' | grep '^utun'); do
  if ifconfig "$iface" 2>/dev/null | grep -q 'inet '; then
    VPN_ACTIVE=1
    break
  fi
done

if [ "$VPN_ACTIVE" -eq 1 ]; then
  ICON=$(printf '\xF3\xB0\x95\xA5')    # shield-check  U+F0565
  COLOR=0xff94e2d5                      # catppuccin teal (on)
else
  ICON=$(printf '\xF3\xB0\xA6\x9D')    # shield-off    U+F099D
  COLOR=0xff6c7086                      # dim overlay0
fi

sketchybar --set "$NAME" icon="$ICON" icon.color=$COLOR label=""
