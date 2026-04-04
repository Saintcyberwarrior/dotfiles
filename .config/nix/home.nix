{ config, pkgs, ... }:

{
  home.stateVersion = "23.11"; # Match your initial install version

  home.packages = with pkgs; [
    # Add user-specific packages here if not in flake.nix
  ];

  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    initContent = ''
      # Source the manual .zshrc
      if [ -f $HOME/.config/zsh/.zshrc ]; then
        source $HOME/.config/zsh/.zshrc
      fi
      
      # Ensure ZDOTDIR is set for future shells
      export ZDOTDIR=$HOME/.config/zsh
    '';

    shellAliases = {
      ls = "ls -G";
      ll = "ls -lG";
      la = "ls -laG";
      v = "nvim";
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "gravity";
        email = "gravity@example.com";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      signing.format = "openpgp";
    };
  };

  # Neovim configuration is already in .config/nvim, 
  # but we can manage the package here
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
