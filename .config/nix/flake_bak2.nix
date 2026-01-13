{
  description = "Gravity nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    #HOME MANAGER
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";


  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, ...}:
  let
    username = "gravity";
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      nixpkgs.config.allowUnfree = true;
      services.sketchybar.enable = true;
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

  # Languages / Dev
  go
  nodejs
  lua
  lua-language-server
  stylua
  gdb-dashboard
  codex
  gemini-cli

  # Media / Docs
  ffmpeg
  mpv
  pandoc
  typst
  zathura
  gnuplot
  gsl

  # Utilities
  mkalias
];


      
	system.primaryUser = "gravity";

	users.users.gravity = {
		name = username;
		home = "/Users/gravity";
	};

homebrew = {
  enable = true;

  brews = [
    "mas"
    "check"
  ];

  casks = [
    # Browsers
    "firefox"
    "orion"
    "tor-browser"

    # Terminal
    "ghostty"

    # Window / Automation
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
};



	 fonts.packages = with pkgs; [
	 	nerd-fonts.hack
		sketchybar-app-font
  		nerd-fonts.jetbrains-mono
  		nerd-fonts.droid-sans-mono
	];
#--------------------------
#  services.yabai = {
#  enable = true;
#  enableScriptingAddition = true;
#};

#services.skhd = {
#  enable = true;
#};

#---------------------------------
	system.activationScripts.applications.text = let
  		env = pkgs.buildEnv {
    			name = "system-applications";
    			paths = config.environment.systemPackages;
    			pathsToLink = "/Applications";
  		};
	in
  		pkgs.lib.mkForce ''
  		# Set up applications.
  		echo "setting up /Applications..." >&2
  		rm -rf /Applications/Nix\ Apps
  		mkdir -p /Applications/Nix\ Apps
  		find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
  		while read -r src; do
    			app_name=$(basename "$src")
    			echo "copying $src" >&2
    			${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
  		done
      			'';

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#air
    darwinConfigurations."air" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
