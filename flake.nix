# https://xyno.space/post/nix-darwin-introduction
# https://github.com/Misterio77/nix-starter-configs/tree/main/standard
# https://sourcegraph.com/github.com/shaunsingh/nix-darwin-dotfiles@8ce14d457f912f59645e167707c4d950ae1c3a6e/-/blob/flake.nix
{

  inputs = {
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    graham33.url = "github:graham33/nur-packages";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs-stable-patched.url = "github:majbacka-labs/nixpkgs/patch-init1sh";
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
    , graham33
    , home-manager
    , nixpkgs
    , nixpkgs-stable-patched
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
          inherit (config.packages)
            himalaya
            libedgetpu
            alsa-hwid
            notmuch-vim;
        };

        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

        devShells = {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              cpio
              git
              jq
              nix
              ripgrep
              rsync
              sops
              ssh-to-age
              zstd
            ];
          };
        };

        packages = with flake.nixosConfigurations; {
          "alsa-hwid" = pkgs.callPackage ./packages/alsa-hwid { };
          "savilerow" = pkgs.callPackage ./packages/savilerow { };
          "prism" = pkgs.callPackage ./packages/prism {
            java = pkgs.openjdk17;
            stdenv = if pkgs.stdenv.isDarwin then pkgs.gccStdenv else pkgs.stdenv;
          };
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
          "notmuch-vim" = pkgs.vimUtils.buildVimPlugin {
            pname = "notmuch-vim";
            version = pkgs.notmuch.version;
            src = pkgs.fetchFromGitHub {
              owner = "felipec";
              repo = "notmuch-vim";
              rev = "v0.7";
              hash = "sha256-fjXq15ORSEbUkPLjOlYPWnZ7aSDYe+XDmPn5GXnEP0M=";
            };
          };
          "libedgetpu" = inputs.graham33.packages.${system}.libedgetpu;

          "kotikone" = kotikone.config.system.build.squashfs;
          "matrix-ponkila-com" = matrix-ponkila-com.config.system.build.kexecTree;
          "minimal" = minimal.config.system.build.kexecTree;
          "muro" = muro.config.system.build.squashfs;
          "starlabs" = starlabs.config.system.build.kexecTree;
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
              ./nixosConfigurations/muro
              ./nix-settings.nix
              ./system/ramdisk.nix
              ./system/netboot.nix
              ponkila.nixosModules.muro
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
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
              ./nixosConfigurations/starlabs
              ./nix-settings.nix
              ./system/ramdisk.nix
              ./system/netboot.nix
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
              {
                home-manager.sharedModules = [
                  nixvim.homeManagerModules.nixvim
                ];
                home-manager.useGlobalPkgs = true;
              }
            ];
          };

          kotikone = {
            system = "x86_64-linux";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./nixosConfigurations/kotikone
              ./nix-settings.nix
              ./system/netboot.nix
              ./system/ramdisk.nix
              {
                nixpkgs.overlays = [
                  wayland.overlay
                ];
              }
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
              ./home-manager/core.nix
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
            "matrix-ponkila-com" = nixosSystem matrix-ponkila-com;
            "minimal" = nixosSystem minimal;
            "starlabs" = nixosSystem starlabs;
          } // (with nixpkgs-stable-patched.lib; {
            "kotikone" = nixosSystem kotikone;
            "muro" = nixosSystem muro;
          });

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
