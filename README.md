# Omarchy GitHub Menu

Adds a **GitHub** row to the [Omarchy](https://omarchy.org/) menu. Select it to fuzzy-search every repository you can access — your own, ones you collaborate on, and every org you belong to — and press Enter to open the repo in your browser.

Public and private repos get different icons, descriptions are shown under each name, and archived repos sort to the bottom.

## Requirements

- Omarchy
- GitHub CLI, logged in: `omarchy pkg add github-cli && gh auth login`
- `python3` (used only by the installer)

## Install

```bash
git clone https://github.com/mranallo/omarchy-github-menu.git && cd omarchy-github-menu
./install.sh                # script + menu row
./install.sh --keybinding   # same, plus SUPER + CTRL + G
```

This copies `omarchy-github-repos` to `~/.local/bin`, adds one marked block to `~/.config/omarchy/extensions/omarchy-menu.jsonc` (hot-reloads, no restart), and — with `--keybinding` — one marked block to `~/.config/hypr/bindings.lua`. It never touches `/usr/share/omarchy`. Re-running is safe; it replaces its own blocks.

`SUPER + CTRL + <letter>` is Omarchy's convention for opening a specific menu. If `SUPER + CTRL + G` is already taken, the installer skips the binding and says so; bind any key yourself:

```lua
o.bind("SUPER + CTRL + G", "GitHub repos", "omarchy-github-repos")
```

## Use

Open the Omarchy menu (`SUPER + SPACE`) → **GitHub**, or press the keybinding. Type to filter, Enter to open.

The first run builds the repo list, which can take 20 seconds or more for large orgs. After that it is cached in `~/.cache/omarchy-github/repos.tsv`; a cache older than 6 hours is shown instantly and refreshed in the background. Force a refresh any time:

```bash
omarchy-github-repos --refresh
```

## Hide orgs you don't want

List owners or orgs, one per line, in `~/.config/omarchy-github/exclude`:

```
# legacy org, mostly archived
ministrycentered
```

The cache rebuilds the next time you open the picker after editing the file.

## Uninstall

```bash
./install.sh --uninstall
```

Removes the script, both marked blocks and the cache. Your exclude list is left in place.
