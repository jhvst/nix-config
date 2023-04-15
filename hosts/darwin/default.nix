{ inputs, outputs, config, lib, pkgs, ... }: {

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
    };

    buildMachines = [
      {
        hostName = "muro";
        systems = [ "i686-linux" "x86_64-linux" "aarch64-linux" ];
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" ];
        maxJobs = 24;
      }
      {
        hostName = "ponkila-ephemeral-beta";
        systems = [ "i686-linux" "x86_64-linux" "aarch64-linux" ];
        supportedFeatures = [ "nixos-test" ];
        maxJobs = 12;
      }
    ];
    distributedBuilds = true;
    # optional, useful when the builder has a faster internet connection than yours
    extraOptions = ''
      builders-use-substitutes = true
    '';

    package = pkgs.nix;

  };

  services.nix-daemon.enable = true;

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "iA-Writer" ]; })
  ];

  environment = {
    systemPackages = with pkgs; [
      discord
      mpv
      utm
    ];
  };

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
      "balenaetcher"
      "element"
      "firefox"
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

  home-manager.users.juuso = { pkgs, ... }: {

    home.stateVersion = "23.05";

    programs.nix-index.enable = true;
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    sops = {
      defaultSopsFile = ./secrets/default.yaml;
      gnupg = with config.home-manager.users.juuso.home; {
        home = "${homeDirectory}/.gnupg/trezor";
      };
      secrets."wireguard/ponkila.conf" = {
        path = "%r/wireguard/ponkila.conf";
      };
      secrets."git/sendemail" = {
        path = "%r/git/sendemail";
      };
    };

    home.packages = with pkgs; [
      bind # nslookup
      exiftool
      file
      gnupg
      lsof
      nmap
      pam-reattach
      passage
      pngquant
      ripgrep-all
      socat
      tree
      trezor_agent
      trezord
      unar
      watch
      wireguard-go
      wireguard-tools
      yle-dl
    ];

    programs.fish = with config.home-manager.users.juuso; {
      enable = true;
      loginShellInit = ''
        set -x EDITOR nvim
        set -x ponkila (getconf DARWIN_USER_TEMP_DIR)${sops.secrets."wireguard/ponkila.conf".name}
        set -x GNUPGHOME ${home.homeDirectory}/.gnupg/trezor
        set -x PATH '${lib.concatStringsSep ":" [
          "${home.homeDirectory}/.nix-profile/bin"
          "/run/wrappers/bin"
          "/etc/profiles/per-user/${home.username}/bin"
          "/run/current-system/sw/bin"
          "/nix/var/nix/profiles/default/bin"
          "/opt/homebrew/bin"
          "/usr/bin"
          "/sbin"
          "/bin"
        ]}'
      '';
    };

    programs.tmux = {
      enable = true;
      baseIndex = 1;
      plugins = with pkgs.tmuxPlugins; [
        extrakto # Ctrl+a+Tab
        tilish # Option+Enter
        tmux-fzf # Ctrl+a+Shift+f
      ];
      extraConfig = ''
        set -g @tilish-dmenu 'on'
        set -g mouse on

        bind | split-window -h
        unbind %

        set -g focus-events on
      '';
      shortcut = "a";
    };

    programs.fzf.enable = true;

    programs.alacritty = {
      enable = true;
      settings = {
        font = {
          normal.family = "iMWritingMonoS Nerd Font";
          size = 14;
        };
      };
    };

    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      includes = with config.home-manager.users.juuso; [{
        path = sops.secrets."git/sendemail".path;
      }];
      signing.key = "8F84B8738E67A3453F05D29BC2DC6A67CB7F891F";
      signing.signByDefault = true;
      userEmail = "juuso@ponkila.com";
      userName = "Juuso Haavisto";
      ignores = [
        ".DS_Store"
        ".direnv"
      ];
    };
  };

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.stateVersion = 4;
}
