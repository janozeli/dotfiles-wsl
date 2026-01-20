# Agent Guide for dotfiles-wsl

## Overview
This is a WSL2 dotfiles repository using GNU Stow for symlink management. Target environment: Arch Linux on WSL2.

## Installation Commands

```bash
# Full installation (installs yay, dependencies, and applies symlinks)
./install.sh

# Manual symlink application only (after dependencies are installed)
stow --dotfiles -t $HOME .
```

The installation uses `yay` (AUR helper) to install: stow, zsh, git, fzf, zoxide, eza, bat, gh, less, wget, curl, unzip, tldr, oh-my-posh-bin, asdf-vm, direnv.

## Build/Lint/Test Commands

```bash
# Manual verification (no automated tests)
# Source scripts to test: source dot-scripts/script.sh
# Check symlinks: ls -la ~ | grep dotfile-name
# Test aliases and functions in new shell session

# Shell script linting (shellcheck)
shellcheck dot-scripts/*.sh
shellcheck install.sh

# Verify shell configuration
zsh -c 'source ~/.zshrc && echo "OK"'
```

## Shell Script Conventions

### Shebang and Error Handling
- Use `#!/usr/bin/env bash` for bash scripts
- Install scripts: `set -e` (exit on error)
- Utility scripts: `set -euo pipefail` (strict mode)
- Always declare error handling first after shebang

### Function Definitions
- Use snake_case for function names
- Provide usage instructions if arguments required:
  ```bash
  if [ $# -lt 1 ]; then
      echo "usage: gc <owner/repo>" >&2
      exit 1
  fi
  ```

- Return meaningful exit codes:
  - 0: Success
  - 1: General error / no match
  - 2: Invalid arguments
  - 127: Command not found

### Command Existence Checks
- Use `command -v` for command detection:
  ```bash
  if ! command -v fd >/dev/null 2>&1; then
      echo "Erro: 'fd' não encontrado no PATH." >&2
      return 127
  fi
  ```

### Environment Variables
- Define defaults with `${VAR:-default}` pattern:
  ```bash
  : "${OC_ROOT:=$HOME}"
  : "${OC_EXCLUDES:=.git node_modules .cache}"
  ```

### Output and Logging
- Use colored output for install scripts:
  ```bash
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m'
  print_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
  print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
  print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
  ```

- Always send errors to stderr (`>&2`)

### Shellcheck Directives
- Add inline shellcheck directives for shellcheck compatibility:
  ```bash
  # shellcheck disable=SC2206
  excludes=($OC_EXCLUDES)
  ```

### Script Modes (Source vs Execute)
- Scripts should support both sourcing and direct execution:
  ```bash
  if (return 0 2>/dev/null); then
      : # sourced - just define functions
  else
      main_function "$@"
  fi
  ```

### Documentation
- Include inline usage examples at script top
- Use heredocs for help text
- Document environment variables, commands, and requirements

## File Naming Conventions

- Hidden files use `dot-` prefix (e.g., `dot-zshrc` becomes `~/.zshrc`)
- Scripts go in `dot-scripts/` directory (or `~/.scripts/` when symlinked)
- Executable scripts in `dot-scripts/` should have no extension
- Directories that should not be symlinked listed in `.stow-local-ignore`

## Zsh Configuration

### Structure
- `dot-zshrc`: Core zsh configuration, sources `~/.zshrc_extend`
- `dot-zshrc_extend`: Extended configuration (plugins, aliases, shell integrations)

### Zinit Plugin Management
- Plugins managed via zinit in `dot-zshrc_extend`
- Syntax: `zinit light <plugin>` for lightweight plugins
- Syntax: `zinit snippet OMZP::<plugin>` for Oh My Zsh plugins
- Current plugins:
  - zsh-users/zsh-syntax-highlighting
  - zsh-users/zsh-completions
  - zsh-users/zsh-autosuggestions
  - Aloxaf/fzf-tab

### Shell Integrations
- fzf: `eval "$(fzf --zsh)"`
- zoxide: `eval "$(zoxide init --cmd cd zsh)"`
- direnv: `eval "$(direnv hook zsh)"`
- oh-my-posh: Custom theme from GitHub
- asdf: Path and completion setup

### History Configuration
```bash
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups
```

### Completion Styling
- Case-insensitive matching: `m:{a-z}={A-Za-z}`
- Colors from LS_COLORS
- fzf-tab previews for cd and zoxide

## Aliases
- `szsh`: Reload zshrc
- `cc`: Clear screen
- `..`: cd ..
- `ls`: eza with header, long format, icons, git
- `cat`: bat (syntax highlighting)
- `zshrc`: Edit .zshrc
- `zshrce`: Edit .zshrc_extend

## Path Management (WSL-specific)
Custom function `wsl_linux_path_first_unique` ensures Linux paths appear before Windows paths in $PATH while removing duplicates. This is critical for WSL2 environments.

## WSL Configuration
- Primary focus: WSL2 with Arch Linux
- Path ordering critical: Linux tools before Windows tools
- Symlink management via GNU Stow: `stow --dotfiles -t $HOME .`

## Adding New Files
1. Create file with `dot-` prefix for hidden files in home
2. Add to `.stow-local-ignore` if it shouldn't be symlinked (e.g., .git, install.sh)
3. Run `stow --dotfiles -t $HOME .` to apply
4. Test by checking symlink in home directory

## No Testing Framework
This repository does not use automated testing. Manual verification required:
- Source scripts to test: `source dot-scripts/script.sh`
- Check symlinks: `ls -la ~ | grep dotfile-name`
- Test aliases and functions in new shell session
- Run shellcheck on all scripts before committing
