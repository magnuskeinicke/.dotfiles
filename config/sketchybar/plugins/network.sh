#!/usr/bin/env bash
# Network indicator (icon-only). UTF-8 bytes via printf to support bash 3.2.
#
# When a VPN is up, the default route goes through a tunnel interface
# (utun*, ipsec*, ppp*). Those interfaces aren't useful for picking a
# wifi/ethernet glyph and `ipconfig getifaddr` returns nothing for them,
# so we fall through to the first active physical interface (en0, en1…).
# The VPN state itself is shown by the separate vpn.sh indicator.

DEF_IFACE=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')

IFACE="$DEF_IFACE"
case "$DEF_IFACE" in
  ""|utun*|ipsec*|ppp*|tun*|tap*)
    IFACE=""
    for cand in $(networksetup -listallhardwareports 2>/dev/null | awk '/Device:/ {print $2}'); do
      info=$(ifconfig "$cand" 2>/dev/null) || continue
      if echo "$info" | grep -q 'status: active' && echo "$info" | grep -q 'inet '; then
        IFACE="$cand"
        break
      fi
    done
    ;;
esac

if [ -z "$IFACE" ]; then
  ICON=$(printf '\xF3\xB0\x96\xAA')    # wifi-off   U+F05AA
else
  HW=$(networksetup -listallhardwareports 2>/dev/null \
        | awk -v iface="$IFACE" '
            /Hardware Port/ {port=$0}
            $0 ~ "Device: "iface {print port; exit}
          ' | sed 's/^Hardware Port: //')
  case "$HW" in
    *Wi-Fi*|*Wireless*)              ICON=$(printf '\xF3\xB0\x96\xA9') ;;  # wifi     U+F05A9
    *Ethernet*|*Thunderbolt*Bridge*) ICON=$(printf '\xF3\xB0\x88\x80') ;;  # ethernet U+F0200
    *)                               ICON=$(printf '\xF3\xB0\x9B\xB3') ;;  # network  U+F06F3
  esac
fi

sketchybar --set "$NAME" icon="$ICON" label=""
