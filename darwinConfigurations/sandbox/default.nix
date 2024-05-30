{ config, pkgs, ... }: {

  services.nix-daemon.enable = true;

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "IBMPlexMono" ]; })
  ];

  networking.hostName = "sandbox";

  environment.systemPackages = with pkgs; [
    discord
    mpv
    ncurses
    pam-reattach
    teams
  ];

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    taps = [
      "homebrew/cask"
    ];
    brews = [ ];
    casks = [
      "element"
      "handbrake"
      "homebrew/cask/dash"
      "numi"
      "remarkable"
      "secretive"
      "signal"
      "slack"
      "sourcetree"
    ];
    masApps = { };
  };

  security.pam.enableSudoTouchIdAuth = true;

  nix.settings.extra-trusted-users = [ "juuso" ];
  users.users.juuso = {
    name = "juuso";
    home = "/Users/juuso";
    shell = pkgs.fish;
  };

  home-manager.users.juuso = {

    sops = with config.home-manager.users.juuso.home; {
      age.keyFile = "${homeDirectory}/.config/age/.age-key.txt";
      defaultSopsFile = ./secrets/default.yaml;
      secrets."wireguard/ponkila.conf" = {
        path = "%r/wireguard/ponkila.conf";
      };
      secrets."email/ponkila.com" = {
        path = "%r/email/ponkila.com";
      };
      secrets."email/mail.com" = {
        path = "%r/email/mail.com";
      };
    };

    programs.alacritty = {
      enable = true;
      settings = {
        font = {
          normal.family = "BlexMono Nerd Font Mono";
          size = 18;
        };
      };
    };

  };

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.stateVersion = 4;
}
