#!/usr/bin/env bash
set -euo pipefail
# source "$(dirname "$0")/00_logging.sh"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y curl gpg

bash "$REPO_DIR/apt/repos.sh"

sudo apt-get update
sudo xargs -a "$REPO_DIR/apt/packages.txt" sudo apt-get install -y

