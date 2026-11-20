# https://xyno.space/post/nix-darwin-introduction
# https://github.com/Misterio77/nix-starter-configs/tree/main/standard
# https://sourcegraph.com/github.com/shaunsingh/nix-darwin-dotfiles@8ce14d457f912f59645e167707c4d950ae1c3a6e/-/blob/flake.nix
{
  inputs = {
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    homestakeros-base.inputs.nixpkgs.follows = "nixpkgs";
    homestakeros-base.url = "github:ponkila/homestakeros?dir=nixosModules/base";
    homestaking-infra.inputs.nixpkgs.follows = "nixpkgs";
    homestaking-infra.url = "github:ponkila/homestaking-infra";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.url = "github:nix-community/nixvim";
    runtime-modules.inputs.nixpkgs.follows = "nixpkgs";
    runtime-modules.url = "github:tupakkatapa/nixos-runtime-modules";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, ... }@inputs:

    inputs.flake-parts.lib.mkFlake { inherit inputs; } rec {

      systems = [ "x86_64-linux" ];
      imports = [
        inputs.agenix-rekey.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.git-hooks-nix.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      perSystem = { pkgs, config, system, inputs', ... }:
        let
          nixpkgs-patched = import
            ((import inputs.nixpkgs { inherit system; }).applyPatches {
              name = "nixpkgs-pr-patches";
              src = inputs.nixpkgs;
              patches = [
                ./patches/499028.patch
              ];
            })
            {
              inherit system;
              config.permittedInsecurePackages = [
                "python3.14-ecdsa-0.19.2"
                "radicle-node-1.10.3"
              ];
            };
        in

        {

          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
            ];
            config = {
              permittedInsecurePackages = [
                "python3.13-ecdsa-0.19.2"
                "radicle-node-1.10.3"
              ];
            };
          };

          overlayAttrs = {
            inherit (config.packages)
              fstar-vscode-assistant
              libedgetpu
              passage
              ndi
              trezor-agent
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

          pre-commit = {
            check.enable = true;
            settings.hooks = {
              flake-checker.enable = true;
              treefmt = {
                enable = true;
                package = config.treefmt.build.wrapper;
              };
            };
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
                xkcdpass
                yubioath-flutter
              ];
              shellHook = ''
                ${config.pre-commit.installationScript}
              '';
            };
          };

          packages = {
            "fstar-vscode-assistant" = pkgs.callPackage ./packages/fstar-vscode-assistant { };
            "savilerow" = pkgs.callPackage ./packages/savilerow { };
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
            "ndi" = pkgs.ndi.overrideAttrs (oldAttrs: {
              src = oldAttrs.src.overrideAttrs (_: {
                outputHash = "sha256-GwZsygdtPotJpfHcf793BllnJWgH48teo4fFdBdurOY=";
              });
            });
            "trezor-agent" = nixpkgs-patched.trezor-agent;
            "python313" = pkgs.python313.override {
              packageOverrides = _: _: {
                inherit (nixpkgs-patched.python313Packages) trezor-agent;
              };
            };

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
              ./nix-settings.nix
              ./nixosConfigurations/muro
              inputs.agenix-rekey.nixosModules.default
              inputs.agenix.nixosModules.default
              inputs.home-manager.nixosModules.home-manager
              inputs.homestakeros-base.nixosModules.kexecTree
              inputs.runtime-modules.nixosModules.runtimeModules
              inputs.sops-nix.nixosModules.sops
              self.homeModules.default
              self.nixosModules.default
              self.nixosModules.uxplay
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
                services.runtimeModules = {
                  enable = true;
                  flakeUrl = "path:${self.outPath}";
                  modules = [
                    {
                      name = "gaming";
                      imports = [ ./runtimeModules/gaming.nix ];
                      skipValidation = true;
                    }
                    {
                      name = "teleconference";
                      imports = [ ./runtimeModules/telco.nix ];
                    }
                    {
                      name = "research";
                      imports = [ ./runtimeModules/research.nix ];
                      skipValidation = true;
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
              ./nix-settings.nix
              ./nixosConfigurations/starlabs
              inputs.agenix-rekey.nixosModules.default
              inputs.agenix.nixosModules.default
              inputs.home-manager.nixosModules.home-manager
              inputs.homestakeros-base.nixosModules.kexecTree
              inputs.homestaking-infra.nixosModules.monitoring
              inputs.runtime-modules.nixosModules.runtimeModules
              inputs.sops-nix.nixosModules.sops
              self.homeModules.default
              self.nixosModules.default
              self.nixosModules.uxplay
              {
                age.rekey = {
                  localStorageDir = ./nixosConfigurations/starlabs/secrets/agenix-rekey;
                  masterIdentities = [{
                    identity = ./nixosModules/agenix-rekey/masterIdentities/juuso.hmac;
                    pubkey = "age12lz3jyd2weej5c4mgmwlwsl0zmk2tdgvtflctgryx6gjcaf3yfsqgt7rnz";
                  }];
                  storageMode = "local";
                };
                services.runtimeModules = {
                  enable = true;
                  flakeUrl = "path:${self.outPath}";
                  modules = [
                    {
                      name = "gaming";
                      imports = [ ./runtimeModules/gaming.nix ];
                      skipValidation = true;
                    }
                    {
                      name = "research";
                      imports = [ ./runtimeModules/research.nix ];
                      skipValidation = true;
                    }
                  ];
                };
              }
            ];
          };

        in
        {

          nixosConfigurations = {
            "muro" = inputs.nixpkgs.lib.nixosSystem muro;
            "starlabs" = inputs.nixpkgs.lib.nixosSystem starlabs;
          };

          nixosModules = {
            default = { imports = [ ./nixosModules ]; };
            neovim = { imports = [ ./nixosModules/neovim ]; };
            uxplay = { imports = [ ./nixosModules/uxplay ]; };
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
