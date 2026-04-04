# Project Context: Gravity's Dotfiles (Rice)

## Overview
This project is a macOS-centric "rice" (system customization) built on an Apple M1 Silicon device. It aims for a high-efficiency CLI/TUI-driven workflow while maintaining aesthetic appeal (Catppuccin/Gruvbox themes). The system is currently managed using a mix of **nix-darwin**, **Homebrew**, and **GNU Stow**.

## Core Stack
- **OS**: macOS (aarch64-darwin)
- **Package Manager**: Nix (nix-darwin) + Homebrew (for GUI/Casks)
- **Window Manager**: `yabai` (tiling) + `skhd` (hotkeys)
- **Status Bar**: `sketchybar`
- **Terminal**: `ghostty`
- **Shell**: `zsh` (with some manual and nix-like config)
- **Multiplexer**: `zellij`
- **Editor**: `neovim` (NvChad-inspired structure, managed via `lazy.nvim` and `Mason`)
- **File Manager**: `yazi`
- **Music**: `mpd` + `ncmpcpp`/`rmpc`
- **Visuals**: `cava`, `btop`

## Current Findings & Learning
1. **Hybrid Management**: The system is in a transitional state between manual dotfiles (Stow) and Nix management. Some configurations (like `yabai`) are enabled in `nix-darwin` but configured via a `.yabairc` in the repository root.
2. **Hardcoded Paths**: Crucial scripts (e.g., `themes/set_theme.sh`) contain absolute paths for a different user (`/Users/camerondixon`), which breaks portability to the current user (`gravity`) and other devices.
3. **Directory Fragmentation**: Some dotfiles live in the root of the repository (`.zshrc`, `.yabairc`), while others are in `.config/`. This makes standardizing with `stow` or `nix` slightly more complex.
4. **Platform Lock-in**: `nix-darwin` is used for almost all package management. While excellent for Mac, it doesn't translate to Linux. Moving user-space configuration to **Home Manager** is the logical next step for cross-platform replication.
5. **Redundancy**: 
    - `sketchybar` is managed by `nix-darwin` but reloaded via `/opt/homebrew/bin/sketchybar` in scripts.
    - Neovim dependencies (LSP/Formatters) are managed via `Mason` but some are also declared in `flake.nix`.
6. **Zsh Configuration**: The `.zshrc` contains a mix of standard Zsh setup and snippets that look like Nix syntax (`programs.zsh.initExtra`), suggesting an incomplete migration.

## Recommendations for Standardization

### 1. Cross-Platform Foundation (Home Manager)
- Integrate **Home Manager** into the Nix Flake.
- Move CLI tool configurations (`zsh`, `neovim`, `zellij`, `yazi`, `git`) from `.config/` or the root into Home Manager modules.
- This allows the same logic to run on Linux by just changing the target system in the Flake.

### 2. Path Generalization
- Replace all instances of `/Users/gravity` or `/Users/camerondixon` with `$HOME` or Nix-interpolated paths.
- Standardize the `dotfiles` location (e.g., using `XDG_CONFIG_HOME`).

### 3. Structural Cleanup
- Move all dotfiles into the `.config/` directory or a dedicated `dotfiles/` source folder.
- Use a single source of truth for theming (e.g., a `theme.nix` or a shared color palette file) that updates `btop`, `cava`, `sketchybar`, and `neovim` simultaneously.

### 4. Modular Nix Architecture
- Split `flake.nix` into:
    - `darwin/`: macOS specific settings (yabai, skhd, system defaults).
    - `home/`: Cross-platform tool configs (Home Manager).
    - `modules/`: Shared functions or themes.

### 5. Neovim Refinement
- Decide between `Mason` (imperative) and `Nix` (declarative) for LSP/tooling. For a "standardized" system, declaring them in Nix is preferred for reproducibility.

## First Hand Suggestions
- **Theming**: Implement a "Global Theme Toggle" using a Nix-generated config file that all other tools read. This avoids `cp` commands in `set_theme.sh`.
- **Zsh**: Clean up the `.zshrc` and move it into `.config/zsh/` to keep the root directory clean.
- **Reproducibility**: Ensure `flake.lock` is always committed and that all external dependencies (like fonts) are pulled via Nix where possible.
