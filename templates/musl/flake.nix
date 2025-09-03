{
  description = "Simple Flake";

  nixConfig = {
    extra-substituters = [
      # Nix community's cache server
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # Nixpkgs (stuff for the system.)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    # Nixpkgs (unstable stuff for certain packages.)
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;

      # Supported systems for your flake packages, shell, etc.
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      # This is a function that generates an attribute by calling a function you
      # pass to it, with each system as an argument
      forAllSystems = nixpkgs.lib.genAttrs systems;

      getSystem =
        system:
        if builtins.getEnv "USE_MUSL" == "true" then
          inputs.nixpkgs-unstable.legacyPackages.${system}.pkgsMusl.stdenv.hostPlatform.config
        else
          inputs.nixpkgs-unstable.legacyPackages.${system}.stdenv.hostPlatform.config;

      packages = forAllSystems (
        system:
        let
          pkgs = (import inputs.nixpkgs-unstable) {
            localSystem = getSystem system;
          };
        in
        {
          mypackage = pkgs.xz;
        }
      );

    in
    {
      inherit packages;
    };
}
