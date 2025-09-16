{ inputs, outputs, config, lib, ... }: {

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mkForce (lib.mapAttrs (_: value: { flake = value; }) inputs);

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

      # Enables local builds, but remote targets
      # Suppose we run the following on `starlabs`:
      # $ nixos-rebuild test --flake .#muro --target-host juuso@192.168.76.40 --use-remote-sudo
      # This:
      # 1. builds the host muro on our local computer
      # 2. transfers the derivations to muro
      # 3. activates the updates configuration on muro
      # You can change the `test` into `build` to do only 1 and 2.
      # To just do the step 1, run:
      # $ nix build .#muro
      trusted-users = [ "root" "@wheel" ];
      connect-timeout = 5; # default is 300s
      warn-dirty = false;
    };

    buildMachines = [ ];
    distributedBuilds = true;
    # optional, useful when the builder has a faster internet connection than yours
    extraOptions = ''
      builders-use-substitutes = true
    '';

  };

  nixpkgs.overlays = [
    outputs.overlays.default
  ];
  nixpkgs.config.allowUnfree = true;

}
