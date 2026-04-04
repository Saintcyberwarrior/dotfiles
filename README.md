# 🌌 Gravity's macOS Rice: Master Manual

This repository contains a declarative, high-performance "rice" for macOS (aarch64-darwin), built on an Apple M1 Silicon device. It unifies system-level management with **nix-darwin** and user-space configuration with **Home Manager**.

## 🚀 Core Stack
- **OS**: macOS (Sonoma/Sequoia+)
- **System Manager**: `nix-darwin`
- **User Config**: `home-manager`
- **WM**: `yabai` (Tiling) + `skhd` (Hotkeys)
- **Status Bar**: `sketchybar` (Dynamic & Responsive)
- **Shell**: `zsh` + `zoxide` + `fast-syntax-highlighting`
- **Editor**: `neovim` (Custom NvChad structure)
- **Music**: `mpd` + `rmpc` (TUI client with Sticker Support)
- **Terminal**: `ghostty` (Fast, GPU-accelerated)

---

## 🛠 Operational Commands

### 1. Applying Changes
Any change made to files in `.config/nix/` requires a rebuild to take effect.
```bash
cd ~/.config/nix
sudo darwin-rebuild switch --flake .#air
```

### 2. Updating the System
Update the Nix flake inputs (to get latest packages) and then rebuild.
```bash
cd ~/.config/nix
nix flake update
sudo darwin-rebuild switch --flake .#air
```

### 3. Maintenance & Garbage Collection
Free up disk space by removing old Nix generations and orphan packages.
```bash
# Clean nix store
nix-store --gc

# Optimization
nix-store --optimise
```

### 4. Theme Switching
The system supports global theme toggling via a specialized script.
```bash
# Set theme to Catppuccin or Gruvbox
bash ~/.config/themes/set_theme.sh Catppuccin
```

---

## 📂 Configuration Mapping

| Component | Location | Managed By |
| :--- | :--- | :--- |
| **System & Apps** | `nix/flake.nix` | nix-darwin |
| **User Profile** | `nix/home.nix` | home-manager |
| **Hotkeys** | `skhd/skhdrc` | nix-darwin (read into flake) |
| **Status Bar** | `sketchybar/` | Standalone / nix-darwin service |
| **Zsh Config** | `zsh/.zshrc` | home-manager (sourced) |
| **Neovim** | `nvim/` | Standalone (Nix ensures binary) |
| **Music (MPD)** | `mpd/mpd.conf` | Manual Service |
| **Lyrics** | `rmpc/flatten_lyrics.py`| Python Script (Custom) |

---

## 🍱 Replicating on Other Machines

### 🍎 To Another Mac
1. Install Nix: `curl -L https://nixos.org/nix/install | sh`.
2. Clone this repo to `~/dotfiles`.
3. Change the `username` variable in `nix/flake.nix` to your local user.
4. Run: `cd ~/dotfiles/.config/nix && nix run nix-darwin -- switch --flake .#air`.

### 🐧 To Linux
This setup is designed to be **Linux-ready**. 
1. The `nix/home.nix` file is cross-platform.
2. You would need a `flake.nix` that uses `nixosConfigurations` instead of `darwinConfigurations`.
3. Move `home-manager` configurations into your NixOS `configuration.nix`.
4. **Note**: `yabai`, `skhd`, and `sketchybar` are macOS specific. On Linux, you would replace them with `i3/sway` and `polybar/waybar`.

### 🪟 To Windows (WSL2)
1. Install WSL2 (Ubuntu).
2. Install Nix in WSL.
3. Use the `home.nix` part of this config to manage your CLI tools (Zsh, Neovim, Git).

---

## ⚠️ Important Considerations


### 1. Absolute Paths
Always prefer `$HOME` or `get_env("HOME")` in scripts. In `nix/flake.nix`, paths are absolute to ensure `sudo` commands (like `darwin-rebuild`) can resolve them correctly.

### 2. Permissions
If Sketchybar or Yabai stop working:
- Check `System Settings > Privacy & Security > Accessibility`.
- Toggle the app OFF and back ON.

---
