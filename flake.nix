# https://xyno.space/post/nix-darwin-introduction
# https://github.com/Misterio77/nix-starter-configs/tree/main/standard
# https://sourcegraph.com/github.com/shaunsingh/nix-darwin-dotfiles@8ce14d457f912f59645e167707c4d950ae1c3a6e/-/blob/flake.nix
{

  inputs = {
    bqnlsp.inputs.nixpkgs.follows = "nixpkgs";
    bqnlsp.url = "sourcehut:~detegr/bqnlsp";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixneovimplugins.url = "github:jooooscha/nixpkgs-vim-extra-plugins";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    ponkila.inputs.nixpkgs.follows = "nixpkgs";
    ponkila.url = "git+ssh://git@github.com/jhvst/ponkila";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sounds.inputs.nixpkgs.follows = "nixpkgs";
    sounds.url = "github:jhvst/nix-config?dir=packages/sounds";
    wayland.inputs.nixpkgs.follows = "nixpkgs";
    wayland.url = "github:nix-community/nixpkgs-wayland";
  };

  # add the inputs declared above to the argument attribute set
  outputs =
    { self
    , bqnlsp
    , darwin
    , flake-parts
    , home-manager
    , nixneovimplugins
    , nixpkgs
    , nixvim
    , ponkila
    , sops-nix
    , wayland
    , ...
    }@inputs:

    flake-parts.lib.mkFlake { inherit inputs; } rec {

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem = { pkgs, lib, config, system, ... }: {
        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
        devShells = {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              cpio
              git
              jq
              nix
              rsync
              ssh-to-age
              zstd
              ripgrep
            ];
          };
        };
        packages = with flake.nixosConfigurations; {
          "bqn-vim" = pkgs.callPackage ./packages/bqn-vim { };
          "savilerow" = pkgs.callPackage ./packages/savilerow { };
          "nvim-bqn" = pkgs.vimUtils.buildVimPluginFrom2Nix {
            pname = "nvim-bqn";
            version = "unstable";
            src = builtins.fetchGit {
              url = "https://git.sr.ht/~detegr/nvim-bqn";
              rev = "bbe1a8d93f490d79e55dd0ddf22dc1c43e710eb3";
            };
            meta.homepage = "https://git.sr.ht/~detegr/nvim-bqn/";
          };
          "sounds" = inputs.sounds.packages.${system}.default;

          "starlabs" = starlabs.config.system.build.kexecTree;
          "muro" = muro.config.system.build.kexecTree;
          "amd" = amd.config.system.build.kexecTree;
          "minimal" = minimal.config.system.build.kexecTree;
          "nvidia" = nvidia.config.system.build.kexecTree;
          "matrix-ponkila-com" = matrix-ponkila-com.config.system.build.kexecTree;
        };
      };

      flake =
        let
          inherit (self) outputs;

          muro = {
            system = "x86_64-linux";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./home-manager/juuso.nix
              ./home-manager/programs/neovim
              ./hosts/muro
              ./nix-settings.nix
              ./system/ramdisk.nix
              ./system/netboot.nix
              ponkila.nixosModules.muro
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
              }
            ];
          };

          starlabs = {
            system = "x86_64-linux";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./home-manager/juuso.nix
              ./home-manager/programs/neovim
              ./hosts/starlabs
              ./nix-settings.nix
              ./system/ramdisk.nix
              ./system/netboot.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
              }
            ];
          };

          amd = {
            system = "x86_64-linux";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./hosts/amd
              ./system/netboot.nix
            ];
          };

          nvidia = {
            system = "x86_64-linux";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./nixosConfigurations/nvidia
              ./system/netboot.nix
            ];
          };

          host-darwin = {
            specialArgs = { inherit inputs outputs; };
            system = "aarch64-darwin"; # "x86_64-darwin" if you're using a pre M1 mac
            modules = [
              ./home-manager/juuso.nix
              ./home-manager/programs/neovim
              ./hosts/darwin
              ./nix-settings.nix
              home-manager.darwinModules.home-manager
              {
                home-manager.sharedModules = [
                  nixvim.homeManagerModules.nixvim
                  sops-nix.homeManagerModules.sops
                ];
                home-manager.useGlobalPkgs = true;
              }
            ];
          };

          minimal = {
            specialArgs = { inherit inputs outputs; };
            system = "x86_64-linux";
            modules = [
              ./nixosConfigurations/minimal
              ./system/netboot.nix
            ];
          };

          matrix-ponkila-com = {
            specialArgs = { inherit inputs outputs; };
            system = "x86_64-linux";
            modules = [
              ./nixosConfigurations/matrix.ponkila.com
              ./system/netboot.nix
              ./system/ramdisk.nix
              ./home-manager/juuso.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
              }
            ];
          };

        in
        {

          overlays = import ./overlays { inherit inputs; };

          nixosConfigurations = with nixpkgs.lib; {
            "starlabs" = nixosSystem starlabs;
            "muro" = nixosSystem muro;
            "amd" = nixosSystem amd;
            "minimal" = nixosSystem minimal;
            "nvidia" = nixosSystem nvidia;
            "matrix-ponkila-com" = nixosSystem matrix-ponkila-com;
          };

          darwinConfigurations = with darwin.lib; {
            "host-darwin" = darwinSystem host-darwin;
          };
        };
    };
}
