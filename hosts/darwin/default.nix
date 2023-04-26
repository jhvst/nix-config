{ inputs, outputs, config, lib, pkgs, ... }: {

  services.nix-daemon.enable = true;

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "iA-Writer" ]; })
  ];

  networking.hostName = "darwin";

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
      "rescuetime"
      "secretive"
      "signal"
      "slack"
      "sourcetree"
    ];
    masApps = { };
  };

  security.pam.enableSudoTouchIdAuth = true;

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
    };

    programs.alacritty = {
      enable = true;
      settings = {
        font = {
          normal.family = "iMWritingMonoS Nerd Font";
          size = 14;
        };
      };
    };

  };

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.stateVersion = 4;
}
