#!/usr/bin/env bash
# Sourced by other scripts. Exports:
#   OS_FAMILY   linux | macos
#   OS_ID       ubuntu, debian, darwin, ...   (best-effort)
#   IS_LINUX    1|0
#   IS_MACOS    1|0

case "$(uname -s)" in
  Linux*)
    OS_FAMILY="linux"
    IS_LINUX=1
    IS_MACOS=0
    if [ -r /etc/os-release ]; then
      # shellcheck disable=SC1091
      OS_ID="$(. /etc/os-release && echo "${ID:-linux}")"
    else
      OS_ID="linux"
    fi
    ;;
  Darwin*)
    OS_FAMILY="macos"
    IS_LINUX=0
    IS_MACOS=1
    OS_ID="darwin"
    ;;
  *)
    OS_FAMILY="unknown"
    IS_LINUX=0
    IS_MACOS=0
    OS_ID="unknown"
    ;;
esac

export OS_FAMILY OS_ID IS_LINUX IS_MACOS
