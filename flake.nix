# https://xyno.space/post/nix-darwin-introduction
# https://github.com/Misterio77/nix-starter-configs/tree/main/standard
# https://sourcegraph.com/github.com/shaunsingh/nix-darwin-dotfiles@8ce14d457f912f59645e167707c4d950ae1c3a6e/-/blob/flake.nix
{

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
  };

  inputs = {
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix.url = "github:ryantm/agenix";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager-stable.inputs.nixpkgs.follows = "nixpkgs-stable";
    home-manager-stable.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    homestakeros-base.url = "github:ponkila/homestakeros/nixos-unstable?dir=nixosModules/base";
    nixpkgs-stable-patched.url = "github:majbacka-labs/nixpkgs/patch-init1sh";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sounds.inputs.nixpkgs.follows = "nixpkgs";
    sounds.url = "github:jhvst/nix-config?dir=packages/sounds";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    wayland.inputs.nixpkgs.follows = "nixpkgs";
    wayland.url = "github:nix-community/nixpkgs-wayland";
    wirenix.url = "sourcehut:~msalerno/wirenix";
  };

  outputs = { self, ... }@inputs:

    inputs.flake-parts.lib.mkFlake { inherit inputs; } rec {

      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.agenix-rekey.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.treefmt-nix.flakeModule
      ];

      perSystem = { pkgs, config, system, ... }: {

        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            self.overlays.default
          ];
          config = { };
        };

        overlayAttrs = {
          inherit (config.packages)
            fstar-vscode-assistant
            libedgetpu
            passage
            seaweedfs;
        };

        treefmt.config = {
          projectRootFile = "flake.nix";
          flakeFormatter = true;
          flakeCheck = true;
          programs = {
            nixpkgs-fmt.enable = true;
            deadnix.enable = true;
            statix.enable = true;
          };
          settings.global.excludes = [ "*/flake.nix" ];
        };

        devShells = {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              config.agenix-rekey.package
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

        packages = {
          "fstar-vscode-assistant" = pkgs.callPackage ./packages/fstar-vscode-assistant { };
          "savilerow" = pkgs.callPackage ./packages/savilerow { };
          "sounds" = inputs.sounds.packages.${system}.default;
          "neovim" = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
            inherit pkgs;
            module = {
              imports = [ self.nixosModules.neovim ];
            };
          };
          "libedgetpu" = pkgs.callPackage ./packages/libedgetpu { };
          "passage" = pkgs.passage.overrideAttrs (_oldAttrs: {
            src = pkgs.fetchFromGitHub {
              owner = "remko";
              repo = "passage";
              rev = "fba940f9e9ffbad7b746f26b8d6323ef6f746187";
              hash = "sha256-1jQCEMeovDjjKukVHaK4xZiBPgZpNQwjvVbrbdeAXrE=";
            };
          });

          "kotikone" = flake.nixosConfigurations.kotikone.config.system.build.squashfs;
          "matrix-ponkila-com" = flake.nixosConfigurations.matrix-ponkila-com.config.system.build.kexecTree;
          "muro" = flake.nixosConfigurations.muro.config.system.build.kexecTree;
          "starlabs" = flake.nixosConfigurations.starlabs.config.system.build.kexecTree;
        };
      };

      flake =
        let
          inherit (self) outputs;

          muro = {
            system = "x86_64-linux";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./home-manager/email.nix
              ./home-manager/juuso.nix
              ./home-manager/programs/neovim
              ./nixosConfigurations/muro
              ./nix-settings.nix
              inputs.homestakeros-base.nixosModules.kexecTree
              inputs.sops-nix.nixosModules.sops
              inputs.agenix-rekey.nixosModules.default
              inputs.agenix.nixosModules.default
              inputs.home-manager-stable.nixosModules.home-manager
              self.nixosModules.wayland
              {
                age.rekey = {
                  localStorageDir = ./nixosConfigurations/muro/secrets/agenix-rekey;
                  masterIdentities = [{
                    identity = ./nixosModules/agenix-rekey/masterIdentities/juuso.hmac;
                    pubkey = "age12lz3jyd2weej5c4mgmwlwsl0zmk2tdgvtflctgryx6gjcaf3yfsqgt7rnz";
                  }];
                  storageMode = "local";
                };
                home-manager.sharedModules = [
                  inputs.nixvim.homeManagerModules.nixvim
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
              inputs.home-manager.nixosModules.home-manager
              inputs.homestakeros-base.nixosModules.kexecTree
              inputs.sops-nix.nixosModules.sops
              inputs.agenix-rekey.nixosModules.default
              inputs.agenix.nixosModules.default
              self.nixosModules.juuso
              {
                age.rekey = {
                  localStorageDir = ./nixosConfigurations/starlabs/secrets/agenix-rekey;
                  masterIdentities = [{
                    identity = ./nixosModules/agenix-rekey/masterIdentities/juuso.hmac;
                    pubkey = "age12lz3jyd2weej5c4mgmwlwsl0zmk2tdgvtflctgryx6gjcaf3yfsqgt7rnz";
                  }];
                  storageMode = "local";
                };
                home-manager.sharedModules = [
                  inputs.nixvim.homeManagerModules.nixvim
                ];
                home-manager.useGlobalPkgs = true;
              }
            ];
          };

          kotikone = {
            system = "x86_64-linux";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./nix-settings.nix
              ./nixosConfigurations/kotikone
              inputs.agenix.nixosModules.default
              inputs.agenix-rekey.nixosModules.default
              inputs.homestakeros-base.nixosModules.kexecTree
              {
                age.rekey = {
                  localStorageDir = ./nixosConfigurations/kotikone/secrets/agenix-rekey;
                  masterIdentities = [{
                    identity = ./nixosModules/agenix-rekey/masterIdentities/juuso.hmac;
                    pubkey = "age12lz3jyd2weej5c4mgmwlwsl0zmk2tdgvtflctgryx6gjcaf3yfsqgt7rnz";
                  }];
                  storageMode = "local";
                };
                nixpkgs.overlays = [
                  inputs.wayland.overlay
                ];
              }
            ];
          };

          epsilon = {
            specialArgs = { inherit inputs outputs; };
            system = "x86_64-darwin";
            modules = [
              ./darwinConfigurations/epsilon
              ./nix-settings.nix
            ];
          };

          sandbox = {
            specialArgs = { inherit inputs outputs; };
            system = "aarch64-darwin";
            modules = [
              ./home-manager/juuso.nix
              ./home-manager/programs/neovim
              ./darwinConfigurations/sandbox
              ./nix-settings.nix
              inputs.home-manager.darwinModules.home-manager
              {
                home-manager.sharedModules = [
                  inputs.nixvim.homeManagerModules.nixvim
                  inputs.sops-nix.homeManagerModules.sops
                ];
                home-manager.useGlobalPkgs = true;
              }
            ];
          };

          matrix-ponkila-com = {
            specialArgs = { inherit inputs outputs; };
            system = "x86_64-linux";
            modules = [
              ./nix-settings.nix
              ./nixosConfigurations/matrix.ponkila.com
              inputs.agenix-rekey.nixosModules.default
              inputs.agenix.nixosModules.default
              inputs.homestakeros-base.nixosModules.kexecTree
              {
                age.rekey = {
                  localStorageDir = ./nixosConfigurations/matrix.ponkila.com/secrets/agenix-rekey;
                  masterIdentities = [{
                    identity = ./nixosModules/agenix-rekey/masterIdentities/juuso.hmac;
                    pubkey = "age12lz3jyd2weej5c4mgmwlwsl0zmk2tdgvtflctgryx6gjcaf3yfsqgt7rnz";
                  }];
                  storageMode = "local";
                };
              }
            ];
          };

        in
        {

          nixosConfigurations = with inputs.nixpkgs.lib; {
            "starlabs" = nixosSystem starlabs;
          } // (with inputs.nixpkgs-stable-patched.lib; {
            "kotikone" = nixosSystem kotikone;
          }) // (with inputs.nixpkgs-stable.lib; {
            "matrix-ponkila-com" = nixosSystem matrix-ponkila-com;
            "muro" = nixosSystem muro;
          });

          darwinConfigurations = with inputs.darwin.lib; {
            "epsilon" = darwinSystem epsilon;
            "sandbox" = darwinSystem sandbox;
          };

          nixosModules = {
            juuso = { imports = [ ./nixosModules/juuso ]; };
            neovim = { imports = [ ./nixosModules/neovim ]; };
            wayland = { imports = [ ./nixosModules/wayland ]; };
          };
        };
    };
}
