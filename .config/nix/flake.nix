{
  description = "Gravity hardened nix-darwin system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, ... }:
  let
    system = "aarch64-darwin";
    username = "gravity";
  in
  {
    darwinConfigurations."air" = nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit self; };

      modules = [
        ({ pkgs, config, ... }: {

          ############################
          # Nix & system hardening
          ############################

          nixpkgs.config.allowUnfree = true;
          services.sketchybar.enable = true;

          nix.settings = {
            experimental-features = "nix-command flakes";
          };

          nix.enable = true;

          system.stateVersion = 6;
          system.configurationRevision = self.rev or self.dirtyRev or null;

          system.primaryUser = username;
          users.users.${username} = {
            name = username;
            home = "/Users/${username}";
          };

          nixpkgs.hostPlatform = system;

          ############################
          # CLI / TUI packages ONLY
          ############################

          environment.systemPackages = with pkgs; [
            # Core
            neovim
            git
            ripgrep
            fd
            fzf
            zoxide
            stow

            # Terminal / TUI
            zellij
            btop
            fastfetch
            yazi
            cmus
            cava
            mpd
            rmpc

            # Dev
            go
            nodejs
            lua
            lua-language-server
            stylua
            gdb-dashboard
            codex
            gemini-cli
            android-tools

            # Python Stack (ADDED)
            python3
            python3Full
            python312
            poetry
            pipx
            python3Packages.pip
            python3Packages.virtualenv
            python3Packages.ipython
            python3Packages.black
            python3Packages.flake8

            # Media / Docs (CLI)
            ffmpeg
            mpv
            pandoc
            typst
            zathura
            gnuplot
            gsl
            transmission_4

            # Utils
            mkalias
            yabai
            skhd
            sketchybar
          ];

          ############################
          # Fonts
          ############################

          fonts.packages = with pkgs; [
            nerd-fonts.jetbrains-mono
            nerd-fonts.hack
            nerd-fonts.droid-sans-mono
            sketchybar-app-font
          ];

          ############################
          # Homebrew (GUI ONLY)
          ############################

          homebrew = {
            enable = true;

            brews = [
              "mas"
              "check"
              "gsl"
              "media-control"
            ];

            casks = [
              # Browsers
              "firefox"
              "orion"

              # Terminal
              "ghostty"

              # Automation / tiling-safe
              "hammerspoon"

              # Productivity
              "raycast"
              "zotero"

              # Media / GUI
              "darktable"
              "transmission"

              # System
              "mactex"
              "nordvpn"

              # Fonts
              "font-sf-pro"
              "sf-symbols"
            ];

            masApps = { };
          };

          ############################
          # /Applications/Nix Apps
          ############################

          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
              echo "Setting up /Applications/Nix Apps..." >&2
              rm -rf /Applications/Nix\ Apps
              mkdir -p /Applications/Nix\ Apps
              find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              while read -r src; do
                app_name=$(basename "$src")
                ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
              done
            '';

          ############################
          # HARDENING RULES (IMPORTANT)
          ############################
          services.yabai = {
            enable = true;
            enableScriptingAddition = false; # IMPORTANT: keep false
          };
          services.skhd.enable = true;

        })
      ];
    };
  };
}
