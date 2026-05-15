#!/usr/bin/env bash
# SessionStart hook: when a session starts in a git worktree, copy gitignored
# local files from the main repo into the worktree at matching relative paths.
#
# Scope (only files that are also gitignored):
#   - .env / .env.* at any depth
#   - everything under any .claude/ directory (e.g. settings.local.json,
#     hooks, worktrees state)
#   - CLAUDE.local.md (project-local Claude rules)
#   - AGENTS.override.md (local AI overrides)
#
# Skips files already present in the worktree (no clobber).
set -euo pipefail

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$cwd" ] || exit 0
[ -d "$cwd" ] || exit 0

# Must be inside a git repo
git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Resolve main repo working tree (shared across worktrees)
common_git=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
main_repo=$(dirname "$common_git")

# Only act when cwd is a linked worktree, not the main repo
cwd_real=$(realpath "$cwd")
main_real=$(realpath "$main_repo")
[ "$cwd_real" = "$main_real" ] && exit 0

copied=0
# Enumerate candidate files in main repo. Prune heavy/build dirs but DO
# descend into .claude (it's a target). check-ignore filters the rest.
while IFS= read -r -d '' src; do
  rel="${src#$main_repo/}"
  # Only copy if gitignored in the main repo
  git -C "$main_repo" check-ignore -q -- "$rel" || continue
  dst="$cwd/$rel"
  [ -e "$dst" ] && continue
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  copied=$((copied + 1))
done < <(find "$main_repo" \
  \( -path '*/node_modules' -o -path '*/.git' -o -path '*/.next' \
     -o -path '*/dist' -o -path '*/build' -o -path '*/.nx' \
     -o -path '*/tmp' -o -path '*/out-tsc' \) -prune \
  -o -type f \
     \( -name '.env' -o -name '.env.*' \
        -o -name 'CLAUDE.local.md' -o -name 'AGENTS.override.md' \
        -o -path '*/.claude/*' \) \
     -print0)

if [ "$copied" -gt 0 ]; then
  printf 'Copied %d gitignored local file(s) from %s into worktree\n' \
    "$copied" "$main_repo" >&2
fi
exit 0
