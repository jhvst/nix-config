{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git
    htop
    tmux
    vim
    wireguard-go
    wireguard-tools
  ];

  environment.variables = {
    EDITOR = "vim";
  };

  networking.hostName = "epsilon";

  services.nix-daemon.enable = true;
  programs.zsh.enable = true;

  homebrew = {
    enable = true;
    brews = [ "podman" ];
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
