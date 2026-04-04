{
  description = "Gravity hardened nix-darwin system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
  let
    system = "aarch64-darwin";
    username = "gravity";
  in
  {
    darwinConfigurations."air" = nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit self inputs; };

      modules = [
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.${username} = import ./home.nix;
        }
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
            lazygit
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
            # nerd-fonts.jetbrains-mono
            # nerd-fonts.hack
            # nerd-fonts.droid-sans-mono
            # sketchybar-app-font
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
              # Fonts (Native Casks)
              "font-jetbrains-mono-nerd-font"
              "font-hack-nerd-font"
              "font-droid-sans-mono-nerd-font"
              "font-sketchybar-app-font"

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
            config = {
              external_bar = "all:37:0";
              mouse_follows_focus = "on";
              focus_follows_mouse = "autoraise";
              window_zoom_persist = "off";
              window_placement = "second_child";
              window_shadow = "float";
              window_opacity = "on";
              window_opacity_duration = "0.2";
              active_window_opacity = "1.0";
              normal_window_opacity = "1.0";
              window_animation_duration = "0.2";
              window_animation_easing = "ease_out_quint";
              insert_feedback_color = "0xff9dd274";
              split_ratio = "0.50";
              auto_balance = "off";
              mouse_modifier = "fn";
              mouse_action1 = "move";
              mouse_action2 = "resize";
              mouse_drop_action = "swap";
              top_padding = 9;
              bottom_padding = 9;
              left_padding = 9;
              right_padding = 9;
              window_gap = 9;
              layout = "bsp";
            };
            extraConfig = ''
              yabai -m signal --add event=window_created app="Zen" action='yabai -m window --space "$(yabai -m query --spaces --space | jq ".index")"'
              yabai -m rule --add app="^(Calculator|Software Update|Dictionary|VLC|System Preferences|System Settings|Photo Booth|Archive Utility|Python|LibreOffice|App Store|Activity Monitor)$" manage=off
              yabai -m rule --add label="Finder" app="^Finder$" title="(Co(py|nnect)|Move|Info|Pref)" manage=off
              yabai -m rule --add label="Safari" app="^Safari$" title="^(General|(Tab|Password|Website|Extension)s|AutoFill|Se(arch|curity)|Privacy|Advance)$" manage=off
              yabai -m rule --add label="About This Mac" app="System Information" title="About This Mac" manage=off
              yabai -m rule --add label="Select file to save to" app="^Inkscape$" title="Select file to save to" manage=off
              yabai -m signal --add event=display_changed action="sketchybar --restart; yabai --restart-service"
            '';
          };

          services.skhd = {
            enable = true;
            skhdConfig = builtins.readFile ../skhd/skhdrc;
          };

        })
      ];
    };
  };
}
