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

      extra-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

    };

    buildMachines = [
      {
        hostName = "muro";
        systems = [ "i686-linux" "x86_64-linux" ];
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" ];
        maxJobs = 24;
      }
      {
        systems = [ "aarch64-linux" "i686-linux" "x86_64-linux" ];
        supportedFeatures = [ "benchmark" "big-parallel" "kvm" "nixos-test" ];
        sshUser = "juuso";
        hostName = "buidl0.ponkila.com";
        maxJobs = 20;
      }
      {
        systems = [ "aarch64-linux" "armv7l-linux" ];
        supportedFeatures = [ "benchmark" "big-parallel" "gccarch-armv8-a" "kvm" "nixos-test" ];
        sshUser = "juuso";
        hostName = "buidl1.ponkila.com";
        maxJobs = 16;
      }
    ];
    distributedBuilds = true;
    # optional, useful when the builder has a faster internet connection than yours
    extraOptions = ''
      builders-use-substitutes = true
    '';

  };

  nixpkgs.overlays = [
    inputs.nixneovimplugins.overlays.default
    inputs.wayland.overlay
    outputs.overlays.modifications
    outputs.overlays.default
  ];
  nixpkgs.config.allowUnfree = true;

}
