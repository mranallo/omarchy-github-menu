#!/bin/bash
# Install the "GitHub" row for the Omarchy menu.
#   ./install.sh                 install script + menu row
#   ./install.sh --keybinding    ...and bind SUPER + CTRL + G
#   ./install.sh --uninstall     remove everything this installer added
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
bin_dir="$HOME/.local/bin"
menu="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
bindings="$HOME/.config/hypr/bindings.lua"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/omarchy-github"
menu_begin="  // omarchy-github-menu: begin"
menu_end="  // omarchy-github-menu: end"
bind_begin="-- omarchy-github-menu: begin"
bind_end="-- omarchy-github-menu: end"

# Remove a marked block (inclusive) from a file, if present.
strip_block() { # file begin end
  [[ -f $1 ]] && grep -qF -- "$2" "$1" || return 0
  python3 - "$1" "$2" "$3" <<'PY'
import sys
path, begin, end = sys.argv[1:]
out, skip = [], False
for line in open(path).read().split("\n"):
    if line.rstrip() == begin.rstrip(): skip = True; continue
    if skip:
        if line.rstrip() == end.rstrip(): skip = False
        continue
    out.append(line)
open(path, "w").write("\n".join(out))
PY
}

if [[ ${1:-} == --uninstall ]]; then
  rm -f "$bin_dir/omarchy-github-repos"
  strip_block "$menu" "$menu_begin" "$menu_end"
  strip_block "$bindings" "$bind_begin" "$bind_end"
  rm -rf "$cache_dir"
  echo "Removed. (Your ~/.config/omarchy-github/exclude list was left in place.)"
  exit 0
fi

command -v omarchy >/dev/null || { echo "This needs Omarchy (omarchy not found)." >&2; exit 1; }
command -v gh >/dev/null || { echo "Install the GitHub CLI first: omarchy pkg add github-cli" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required by this installer." >&2; exit 1; }
gh auth status >/dev/null 2>&1 || echo "Note: run 'gh auth login' before first use." >&2

mkdir -p "$bin_dir"
install -m 755 "$here/bin/omarchy-github-repos" "$bin_dir/omarchy-github-repos"

# Menu row: add (or replace) a marked block just before the closing brace.
mkdir -p "$(dirname "$menu")"
if [[ ! -f $menu ]]; then
  cp /usr/share/omarchy/config/omarchy/extensions/omarchy-menu.jsonc "$menu"
fi
strip_block "$menu" "$menu_begin" "$menu_end"
python3 - "$menu" "$menu_begin" "$menu_end" <<'PY'
import re, sys
path, begin, end = sys.argv[1:]
s = open(path).read().rstrip()
assert s.endswith("}"), "unexpected menu file layout"
body = s[:-1].rstrip()
# Ensure the previous real entry ends with a comma (skip comments/blank lines).
lines = body.split("\n")
for i in range(len(lines) - 1, -1, -1):
    t = lines[i].strip()
    if not t or t.startswith("//"): continue
    if not t.endswith(("{", ",")): lines[i] = lines[i].rstrip() + ","
    break
block = [begin,
  '  "github": {"icon":"\\uf09b","label":"GitHub","aliases":["repos"],"description":"Search all repositories","action":"omarchy-github-repos"},',
  end]
open(path, "w").write("\n".join(lines + [""] + block) + "\n}\n")
PY
echo "Added GitHub row to the Omarchy menu."

if [[ ${1:-} == --keybinding ]]; then
  strip_block "$bindings" "$bind_begin" "$bind_end"
  if grep -q 'SUPER + CTRL + G"' "$bindings" 2>/dev/null; then
    echo "SUPER + CTRL + G is already bound in $bindings; skipping keybinding." >&2
  else
    {
      echo ""
      echo "$bind_begin"
      echo 'o.bind("SUPER + CTRL + G", "GitHub repos", "omarchy-github-repos")'
      echo "$bind_end"
    } >>"$bindings"
    echo "Bound SUPER + CTRL + G."
  fi
fi

echo "Done. Warming the repo cache in the background..."
(setsid "$bin_dir/omarchy-github-repos" --refresh >/dev/null 2>&1 &)
