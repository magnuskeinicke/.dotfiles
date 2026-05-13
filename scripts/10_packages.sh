#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./_os.sh
source "$REPO_DIR/scripts/_os.sh"

if [ "$OS_FAMILY" = "linux" ]; then
  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt-get install -y curl gpg

  bash "$REPO_DIR/apt/repos.sh"

  sudo apt-get update
  sudo xargs -a "$REPO_DIR/apt/packages.txt" sudo apt-get install -y
elif [ "$OS_FAMILY" = "macos" ]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "==> Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Add brew to PATH for the rest of this script (Apple Silicon vs Intel).
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  brew update
  BREWFILE="$REPO_DIR/brew/Brewfile"
  if [ ! -f "$BREWFILE" ]; then
    echo "ERROR: Missing $BREWFILE"
    exit 1
  fi
  brew bundle --file="$BREWFILE"
else
  echo "ERROR: Unsupported OS_FAMILY=$OS_FAMILY"
  exit 1
fi
