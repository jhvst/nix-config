# https://xyno.space/post/nix-darwin-introduction
# https://github.com/Misterio77/nix-starter-configs/tree/main/standard
# https://sourcegraph.com/github.com/shaunsingh/nix-darwin-dotfiles@8ce14d457f912f59645e167707c4d950ae1c3a6e/-/blob/flake.nix
{

  inputs = {
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
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
    , darwin
    , flake-parts
    , home-manager
    , nixpkgs
    , nixvim
    , ponkila
    , sops-nix
    , wayland
    , ...
    }@inputs:

    flake-parts.lib.mkFlake { inherit inputs; } rec {

      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      perSystem = { pkgs, lib, config, system, ... }: {

        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            self.overlays.default
          ];
          config = { };
        };

        overlayAttrs = {
          inherit (config.packages) himalaya;
        };

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
          "savilerow" = pkgs.callPackage ./packages/savilerow { };
          "sounds" = inputs.sounds.packages.${system}.default;
          "himalaya" = pkgs.himalaya.overrideAttrs (oldAttrs: {
            buildInputs = oldAttrs.buildInputs ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.darwin.Security ];
          });
          "neovim" = nixvim.legacyPackages.${system}.makeNixvimWithModule {
            inherit pkgs;
            module = {
              imports = [ self.nixosModules.neovim ];
            };
          };

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
                home-manager.sharedModules = [
                  nixvim.homeManagerModules.nixvim
                ];
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
                home-manager.sharedModules = [
                  nixvim.homeManagerModules.nixvim
                ];
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
            "amd" = nixosSystem amd;
            "matrix-ponkila-com" = nixosSystem matrix-ponkila-com;
            "minimal" = nixosSystem minimal;
            "muro" = nixosSystem muro;
            "nvidia" = nixosSystem nvidia;
            "starlabs" = nixosSystem starlabs;
          };

          darwinConfigurations = with darwin.lib; {
            "host-darwin" = darwinSystem host-darwin;
          };

          nixosModules = {
            neovim = {
              imports = [ ./nixosModules/neovim ];
            };
          };
        };
    };
}
