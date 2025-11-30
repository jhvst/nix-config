# https://xyno.space/post/nix-darwin-introduction
# https://github.com/Misterio77/nix-starter-configs/tree/main/standard
# https://sourcegraph.com/github.com/shaunsingh/nix-darwin-dotfiles@8ce14d457f912f59645e167707c4d950ae1c3a6e/-/blob/flake.nix
{
  inputs = {
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix.inputs.darwin.follows = ""; # optionally choose not to download darwin deps (saves some resources on Linux)
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    homestakeros-base.url = "github:ponkila/homestakeros?dir=nixosModules/base";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    runtime-modules.url = "github:tupakkatapa/nixos-runtime-modules";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sounds.inputs.nixpkgs.follows = "nixpkgs";
    sounds.url = "github:jhvst/nix-config?dir=packages/sounds";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
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

      perSystem = { pkgs, config, system, inputs', ... }:

        let
          nixpkgs-patched = import
            ((import inputs.nixpkgs { inherit system; }).applyPatches {
              name = "nixpkgs-pr-455630";
              src = inputs.nixpkgs;
              patches = [ ./packages/trezor/455630.patch ];
            })
            { inherit system; };
        in
        {

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
              python313
              ;
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
                cobang
                config.agenix-rekey.package
                nix-tree
                sops
                ssh-to-age
                tomb
                yubioath-flutter
              ];
            };
          };

          packages = {
            "fstar-vscode-assistant" = pkgs.callPackage ./packages/fstar-vscode-assistant { };
            "savilerow" = pkgs.callPackage ./packages/savilerow { };
            "sounds" = inputs'.sounds.packages.default;
            "neovim" = inputs'.nixvim.legacyPackages.makeNixvimWithModule {
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
            "python313" = pkgs.python313.override {
              packageOverrides = final: prev: {
                trezor = nixpkgs-patched.python313Packages.trezor;
              };
            };

            "muro" = flake.nixosConfigurations.muro.config.system.build.kexecTree;
            "halo" = flake.nixosConfigurations.halo.config.system.build.kexecTree;
            "starlabs" = flake.nixosConfigurations.starlabs.config.system.build.kexecTree;
          };
        };

      flake =
        let
          inherit (self) outputs;

          halo = {
            system = "x86_64-linux";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./nixosModules/halo3
              ./nix-settings.nix
              ./runtimeModules/gaming.nix
              inputs.homestakeros-base.nixosModules.kexecTree
            ];
          };

          muro = {
            system = "x86_64-linux";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./home-manager/email.nix
              ./home-manager/juuso.nix
              ./home-manager/programs/neovim
              ./nixosConfigurations/muro
              ./nix-settings.nix
              inputs.agenix-rekey.nixosModules.default
              inputs.agenix.nixosModules.default
              inputs.home-manager.nixosModules.home-manager
              inputs.homestakeros-base.nixosModules.kexecTree
              inputs.runtime-modules.nixosModules.runtimeModules
              inputs.sops-nix.nixosModules.sops
              self.homeModules.default
              self.nixosModules.juuso
              self.nixosModules.wayland
              {
                age.rekey = {
                  localStorageDir = ./nixosConfigurations/muro/secrets/agenix-rekey;
                  masterIdentities = [
                    {
                      identity = ./nixosModules/agenix-rekey/masterIdentities/juuso.hmac;
                      pubkey = "age12lz3jyd2weej5c4mgmwlwsl0zmk2tdgvtflctgryx6gjcaf3yfsqgt7rnz";
                    }
                    {
                      identity = ./nixosModules/agenix-rekey/masterIdentities/juuso-yubikey-beta.hmac;
                      pubkey = "age1des79v6xqh3ylway0lwlggf0ldckcej0w3a4njytvq6us2yp3erszz39uk";
                    }
                  ];
                  storageMode = "local";
                };
                home-manager.sharedModules = [
                  inputs.nixvim.homeManagerModules.nixvim
                ];
                home-manager.useGlobalPkgs = true;
                services.runtimeModules = {
                  enable = true;
                  flakeUrl = "path:${self.outPath}";
                  modules = [
                    {
                      name = "gaming";
                      path = ./runtimeModules/gaming.nix;
                    }
                  ];
                };
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
              inputs.agenix-rekey.nixosModules.default
              inputs.agenix.nixosModules.default
              inputs.home-manager.nixosModules.home-manager
              inputs.homestakeros-base.nixosModules.kexecTree
              inputs.runtime-modules.nixosModules.runtimeModules
              inputs.sops-nix.nixosModules.sops
              self.nixosModules.juuso
              self.homeModules.default
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
                services.runtimeModules = {
                  enable = true;
                  flakeUrl = "path:${self.outPath}";
                  modules = [
                    {
                      name = "gaming";
                      path = ./runtimeModules/gaming.nix;
                    }
                  ];
                };
              }
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

        in
        {

          nixosConfigurations = {
            "muro" = inputs.nixpkgs.lib.nixosSystem muro;
            "starlabs" = inputs.nixpkgs.lib.nixosSystem starlabs;
            "halo" = inputs.nixpkgs-stable.lib.nixosSystem halo;
          };

          darwinConfigurations = with inputs.darwin.lib; {
            "sandbox" = darwinSystem sandbox;
          };

          nixosModules = {
            juuso = { imports = [ ./nixosModules/juuso ]; };
            neovim = { imports = [ ./nixosModules/neovim ]; };
            wayland = { imports = [ ./nixosModules/wayland ]; };
          };

          homeModules = {
            default = { imports = [ ./homeModules ]; };
          };

          templates."musl" = {
            path = ./templates/musl;
            description = "Flake template showing musl cross compilation";
          };
        };
    };
}
