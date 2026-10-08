# Dotfiles

Personal configuration for **Omarchy 4**. This repository manages selected user
files with explicit symlinks, keeps development tools in mise, and restores
Neovim from its own repository. It does not replace Omarchy's packaged defaults.

This is my setup, not a general-purpose installer. In particular, the monitor
layout is specific to my two LG displays.

## What's managed

| Deployment package | Configuration |
| --- | --- |
| `git` | Shared Git config at `~/.config/git/config`; private overrides stay local |
| `mise` | Global tool declarations at `~/.config/mise/config.toml` |
| `hypr` | Monitor, input, binding, appearance, and autostart Lua overrides |
| `ghostty` | Ghostty config and `~/.config/xdg-terminals.list` default-terminal preference |
| `fish` | Shell config with Fish's built-in Git prompt, and Catppuccin Macchiato theme |
| `voxtype` | Dictation configuration at `~/.config/voxtype/config.toml` |
| `agent` | Whole skills directory linked under `~/.agents/skills/personal` |
| `pi-extensions` | Whole extensions directory linked at `~/.pi/agent/extensions` |

Hyprland's main `~/.config/hypr/hyprland.lua` loader is **not managed here**.
Omarchy supplies it and loads the personal overrides after its defaults. Nothing
under `/usr/share/omarchy/` is edited. The personal autostart config launches
1Password at Hyprland login with its main window visible, ready to unlock.
1Password must be installed separately; the SSH agent still needs to be enabled
and unlocked/authorized as required.

Ghostty launches Fish without changing the system login shell. Fish and Ghostty
use Catppuccin Macchiato independently of the desktop theme. Pi's theme/settings
are not managed here; its existing `omarchy-system` preference is left alone.
The prompt layout lives in `config.fish` and calls Fish's built-in
`fish_git_prompt`, with native color hints and informative characters enabled:
a green branch name, red `✚` for unstaged changes, green `●` for staged changes,
and blue `…` for untracked files. No separate Git prompt helper is needed.

Neovim is a separate checkout of `git@github.com:crpier/nvim.git`, cloned directly
to `~/.config/nvim`, not symlinked or stored as a submodule.

## Prerequisites

Start with a working Omarchy 4 installation. Deployment needs Bash and Python 3;
repository cloning also needs Git and GitHub access. `--install-tools` requires
mise to be installed already.

The selected configurations additionally need Fish, Ghostty, Neovim, Hyprland,
and Omarchy's `xdg-terminal-exec` integration. On Omarchy, system packages can be
installed explicitly, for example:

```bash
omarchy pkg add fish ghostty neovim mise
```

The deployment checks warn about missing executables and paths. They do not
install system packages, change your login shell, or audit every optional alias
and editor integration. Neovim has its own external-tool health check.

## Restore after reinstalling

### 1. Enable Git access through 1Password

Install/unlock 1Password and enable its SSH agent in **Settings → Developer**.
The key should be an SSH Key item, with its public key registered on GitHub.
Keep the private key in 1Password, not in this repository.

Merge this into `~/.ssh/config` if SSH is not already configured for the agent:

```sshconfig
Host github.com
    IdentityAgent ~/.1password/agent.sock
```

If multiple keys are available, configure the appropriate public-key selector
separately. Agent authorization may require approval in 1Password.

```bash
git clone git@github.com:crpier/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 2. Inspect the preview

```bash
./deploy.sh --list
./deploy.sh --all
```

**Dry-run is the default.** `--all` selects packages; only `--apply` authorizes
changes. A normal preview does not contact GitHub or run mise installation.

Check the hardware-specific `hypr/.config/hypr/monitors.lua` before applying it
on different hardware. The current layout is DP-2 on the left, DP-3 on the right,
both at 2560×1440/~180 Hz and 125% scaling. Workspace placement follows the
numpad columns: **1, 4, 7** belong to DP-2 (left), and **2, 3, 5, 6, 8, 9**
belong to DP-3 (right). Workspace **10** remains dynamic. These rules assign
monitors without keeping empty workspaces persistent or changing keybindings.

### 3. Prepare the Neovim destination

`--clone-repos` refuses unexpected existing directories. A fresh Omarchy install
usually already has a Neovim config. Inspect it, then move it aside before
cloning, choosing a backup path that does not already exist:

```bash
mv -- ~/.config/nvim ~/.config/nvim.before-dotfiles
```

Skip this if the destination is absent or already a checkout of my Neovim repo.
Other Neovim data, plugins, and caches are not deleted by deployment.

### 4. Apply and optionally install tools/clone repositories

```bash
./deploy.sh --all --apply --install-tools --clone-repos
```

These are independent opt-ins:

```bash
./deploy.sh git fish --apply           # Only selected symlink packages
./deploy.sh mise --apply --install-tools
./deploy.sh --all --apply --clone-repos
```

`--install-tools` requires `--apply` and selection of the `mise` package (or
`--all`). It runs `mise install` after linking the global config, from a neutral
working directory rather than the caller's project, and rechecks dependencies.
Downloads/installers can execute code; use this only with reviewed configuration.

`--clone-repos` requires `--apply`. It checks destinations before linking and
clones missing repositories after successful deployment/tool installation. It
never pulls, resets, switches branches, or overwrites an existing checkout.
Existing matching checkouts, including local edits, are left alone. Failed clones
are cleaned up before a destination is published.

### 5. Set the private Git identity

```bash
mkdir -p ~/.config/git
git config --file ~/.config/git/local user.email "YOUR_EMAIL"
chmod 600 ~/.config/git/local
```

The shared author name is `crpier`; override it in the same local file if needed.
A GitHub noreply address is an option, but use the exact address from your account
settings. Keeping an email out of dotfiles does not hide it from commit metadata.

The shared config uses `main`, Neovim as editor, and fast-forward-only pulls.
Divergent branches require an explicit merge or rebase. Commit signing is not
configured by this repository.

Avoid modifying shared preferences with `git config --global`: that can edit or
replace the managed config. Edit the tracked file for shared settings; use
`git config --file ~/.config/git/local ...` for private/machine-specific settings.
Also check for an old `~/.gitconfig`, which can override XDG settings.

### 6. Reload and verify

```bash
hyprctl reload
hyprctl configerrors
omarchy restart terminal
omarchy default terminal
```

The terminal default should be `ghostty`. Open a new terminal window to start
Fish; reloading does not replace a shell already running. Log out and back in
when testing session-wide environment changes such as GTK scaling.

Fish uses mise's vendor activation on Arch, with an interactive fallback when
that hook is absent. Python versions are managed with **uv**, not mise. Mise
currently declares Node, Go, Rust, uv, GitHub CLI, Codex, and Pi. Several use
`latest`, so a fresh restore may install newer versions; pin them if exact
version reproducibility is needed. Installed versions are not stored in Git.

Start Neovim and let its reviewed configuration install plugins. Then run:

```vim
:checkhealth config
```

Language servers, formatters, and linters must be installed separately. Their
configuration, plugin lockfile, and editor fixes belong in the **Neovim repo**,
not this one.

## Voxtype dictation

Only `voxtype/.config/voxtype/config.toml` is tracked. Models, recordings,
transcripts, runtime state, and the generated systemd service stay outside Git.
The current config uses local Whisper **`large-v3`** in English with the
**Vulkan GPU binary variant**, plus vocabulary hints for terms from this setup
(Omarchy, Hyprland, Voxtype, Ghostty, Neovim, mise, and related tools). The hints
bias recognition and spelling; they do not train the model or guarantee matches.
It uses the default microphone,
a 60-second recording limit, media pausing, and whole-text paste via
**Shift + Insert**, with clipboard fallback. This avoids synthetic Super-key
chords triggering compositor menus and works in Ghostty and most Linux text fields.
It restores the previous
clipboard contents after a 500 ms delay. Restoration is best-effort: an empty or
unreadable clipboard, or a failed paste/restore, can leave the transcription on the
clipboard. Dictation can also appear in clipboard history.
Voxtype's own hotkey detection is disabled: Omarchy provides **F9** push-to-talk
and **Super + Ctrl + X** to toggle dictation.

For a fresh installation, run Omarchy's setup **before deploying this config**:

```bash
omarchy voxtype install
voxtype setup --download --model large-v3
sudo voxtype setup variant --to voxtype-vulkan
./deploy.sh voxtype --apply
systemctl --user restart voxtype.service
voxtype info accel
```

`large-v3` downloads about 3 GB of model weights. The Vulkan runtime and GPU driver
must be installed. Binary selection modifies the system Voxtype launcher and is
not stored in the TOML file; repeat that explicit step when restoring this setup.
`voxtype info accel` should report GPU activity, not merely a GPU-capable binary.
Package upgrades may reset the launcher; recheck acceleration afterward.

Omarchy's installer writes a default config, downloads a model, and sets up the
user service. Do not rerun it over a managed config without backing up your changes.
Linking alone does not install Voxtype, download a model, or enable the service.
Deployment warns if Voxtype, `wtype`, `wl-copy`, `wl-paste`, or the configured
model is missing.

If only the current model is missing:

```bash
voxtype setup --download --model large-v3
```

After editing the config, finish any active dictation before restarting the daemon:

```bash
systemctl --user restart voxtype.service
systemctl --user status voxtype.service
```

Configuration/model-selection tools may rewrite the config or replace its symlink;
review `git diff` and rerun `./deploy.sh voxtype --apply` if needed.

## Deployment behavior and backups

- `links.json` declares package mappings. Normal mappings link a file or whole
  directory. `mode: "files"` links the files within a tree individually, keeping
  unrelated destination files intact.
- `checks.json` declares advisory executable checks and home-relative path checks.
  Only selected packages are checked. Warnings do not block deployment.
- `repos.tsv` contains a Git URL and home-relative destination separated by a
  **tab**. Repository cloning is independent of symlink package selection.
- Correct links are left alone on repeated runs. Deleted manifest entries do not
  automatically remove previously deployed links.
- Conflicting files, broken symlinks, or directories are moved into
  `~/.local/state/dotfiles/backups/<UTC timestamp>/`, preserving home-relative
  paths. A whole-directory link replaces the entire directory; it does not merge
  its existing contents. Review existing Pi extensions before replacing them.
- Symlinked/non-directory destination parents are rejected rather than written
  through. No `sudo` is used by the deployment scripts.
- Deployment is **not transactional** across all packages, installations, and
  clones. A later failure keeps earlier successful changes and backups. Fix the
  issue and rerun; check the exit status and output.
- To restore a backed-up file, remove its managed symlink and move the backup to
  the original location. No automated uninstall or full rollback is provided.

Keep the repository at `~/.dotfiles`; links point to its absolute location. Moving
it breaks existing links until redeployment. Programs that rewrite configs by
replacing files may detach symlinks; inspect `git status` and rerun deployment if
necessary.

## Keep out of Git

Do not commit SSH private keys, API tokens, 1Password data, Git's local identity
file, Pi authentication/device/session state, Fish universal-variable state,
editor caches, installed tools, or application history. Machine-local overrides
under `~/.config/local_configs/` are not managed here.

Git is not a backup for documents or password-manager data. Review changes before
committing and push both this repo and the Neovim repo to protect against a disk
wipe. Deployment itself never stages, commits, or pushes.

## Validation

Run from the repository root:

```bash
python3 -m unittest discover -s tests -v
bash tests/test_clone_repos.sh
bash tests/test_fish.sh
bash -n deploy.sh scripts/clone_repos.sh tests/test_clone_repos.sh tests/test_fish.sh
fish --no-execute fish/.config/fish/config.fish
ghostty +validate-config --config-file="$PWD/ghostty/.config/ghostty/config"
git diff --check
git diff --cached --check
```

Deployment and Fish tests use temporary home directories; repository tests use
local remotes, not GitHub. `--home` is available for isolated symlink previews/tests:

```bash
./deploy.sh --all --home /path/to/an/existing/test-home
```

Do not combine a test home with real `--install-tools` unless you intend to run
installers there. Application reloads and real network authentication are manual
integration checks.
