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

          nix.settings = {
            experimental-features = "nix-command flakes";
            #auto-optimise-store = true;
          };
          nix.optimise.automatic = true;

          nix.enable = true;

          # Keep the system clean but rollback-friendly
          nix.gc = {
            automatic = true;
            interval = { Weekday = 0; Hour = 3; Minute = 0; }; # Sundays 03:00
            options = "--delete-older-than 14d";
          };

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
            git-lfs
            ripgrep
            fd
            fzf
            zoxide
            stow
            ncdu

            # Terminal / TUI
            zellij
            btop
            fastfetch
            yazi
            cmus
            #cava
            mpd
            rmpc

            # Dev
            #go
            #nodejs
            lua
            lua-language-server
            stylua
            #gdb-dashboard
            #codex
            gemini-cli
            android-tools
            ollama
            opencode
            claude-code

            # Python Stack (clean)
            python312
            uv
            #poetry
            #pipx

            # Media / Docs (CLI)
            ffmpeg
            mpv
            pandoc
            typst
            zathura
            gnuplot
            # gsl
            transmission_4
            #hugo

            # Utils
            mkalias
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
              #"check"
              "media-control"
              #"graph-tool"
              "mole"
            ];

            casks = [
              # Browsers
              "firefox"
              #"orion"
              "brave-browser"

              # Terminal
              "ghostty"

              # Automation / tiling-safe
              #"hammerspoon"

              # Productivity
              #"raycast"
              "zotero"

              # Media / GUI
              "darktable"
              #"transmission"

              # Editors (GUI)
              #"zed"

              # System
              #"mactex"
              "basictex"
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
                pathsToLink = [ "/Applications" ];
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
          # Window manager + hotkeys + bar
          ############################

          services.sketchybar.enable = true;

          services.yabai = {
            enable = true;
            enableScriptingAddition = true; # SA on (managed declaratively)
          };

          services.skhd.enable = true;

        })
      ];
    };
  };
}
