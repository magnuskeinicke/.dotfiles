#!/usr/bin/env bash
set -euo pipefail
# source "$(dirname "$0")/00_logging.sh"

export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"

command -v gh >/dev/null 2>&1 || { echo "gh is required"; exit 1; }

gh auth status >/dev/null 2>&1 || gh auth login -h github.com -s admin:ssh_signing_key,admin:public_key

read -rp "Git name: " gituser
read -rp "Personal email: " gitemail
read -rp "Company email: " companyemail
read -rp "GitHub SSH key title (e.g. Laptop): " keytitle

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

KEY="$HOME/.ssh/id_ed25519"
PUB="$KEY.pub"

if [ ! -f "$KEY" ]; then
  echo "Generating SSH key (you will be prompted for a passphrase; recommended)."
  ssh-keygen -t ed25519 -a 64 -f "$KEY" -C "$gitemail"
fi

eval "$(ssh-agent -s)" >/dev/null
ssh-add "$KEY"

# Upload keys to GitHub
gh ssh-key add "$PUB" -t "$keytitle - auth" --type authentication || true
gh ssh-key add "$PUB" -t "$keytitle - sign" --type signing || true

# Write git configs (store private key path for signing)
cat > "$HOME/.gitconfig-work" <<EOF
[user]
    name = $gituser
    email = $companyemail
    signingkey = $KEY
[gpg]
    format = ssh
[commit]
    gpgsign = true
[tag]
    gpgsign = true
EOF

cat > "$HOME/.gitconfig" <<EOF
[user]
    name = $gituser
    email = $gitemail
    signingkey = $KEY
[gpg]
    format = ssh
[commit]
    gpgsign = true
[tag]
    gpgsign = true
[includeIf "gitdir:~/Documents/Work/"]
    path = ~/.gitconfig-work
[init]
    defaultBranch = main
EOF

echo "SSH + GitHub + git signing config done."

