#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR/.git" ]; then
  git -C "$TPM_DIR" pull --ff-only
else
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# install TPM plugins (non-fatal if tmux isn't set up yet)
"$TPM_DIR/bin/install_plugins" || true

