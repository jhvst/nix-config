# https://xyno.space/post/nix-darwin-introduction
# https://github.com/Misterio77/nix-starter-configs/tree/main/standard
# https://sourcegraph.com/github.com/shaunsingh/nix-darwin-dotfiles@8ce14d457f912f59645e167707c4d950ae1c3a6e/-/blob/flake.nix
{
  inputs = {
    actions-nix.url = "github:nialov/actions.nix";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix.inputs.darwin.follows = ""; # optionally choose not to download darwin deps (saves some resources on Linux)
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    homestakeros-base.url = "github:ponkila/homestakeros?dir=nixosModules/base";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
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
        inputs.actions-nix.flakeModules.default
        inputs.agenix-rekey.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.treefmt-nix.flakeModule
      ];

      perSystem = { pkgs, config, system, inputs', ... }:

        let
          # nixpkgs-patched is an advanced tactic to solve a very
          # particular problem:
          # suppose there is a patch upstream that depends on a
          # specific version of Python, here, `3.13.8`, but the patch
          # trails the current tip such that the Python version on our
          # inputs.nixpkgs is `3.13.9`.
          #
          # in this case, we have two options:
          # - 1. meticilously override each dependency of the patched
          # package, and every app that depends on it, to use `3.18.8`
          # (in this case, `trezor` and `trezor-agent`)
          # - 2. lock our whole nixpkgs to `3.13.8` and cause a huge
          # recompile due to cache misses
          #
          # what we can do instead is to apply a patch on the upstream
          # inputs.nixpkgs to change the source code such that we
          # automatically gain steps we would do in 1.
          #
          # finally, we can apply configuration parameters that affect
          # only the patched package closure, as done here with the
          # `permittedInsecurePackages`. unfortunately, this closure
          # must be duplicated on both our patched nixpkgs, as well
          # as our upstream nixpkgs (see `nix-settings.nix`).
          # yet, this keeps our configuration tidy and clear regarding
          # what fixes are related to the affected patchset.
          # to cherry-pick patches, we override the package we need
          # (in this case, the whole `python313` package set) with the
          # patched version:
          #
          # ```nix
          # "python313" = pkgs.python313.override {
          #   packageOverrides = _: _: {
          #     inherit (nixpkgs-patched.python313Packages) trezor;
          #   };
          # };
          # ```
          #
          # to apply this override, we add it to our overlays:
          #
          # ```nix
          # overlayAttrs = {
          #   inherit (config.packages) python313;
          # };
          # ```
          #
          # this overlay gets applied to our nixpkgs with:
          #
          # ```nix
          # _module.args.pkgs = import inputs.nixpkgs {
          #   inherit system;
          #   overlays = [ self.overlays.default ];
          # };
          # ```
          #
          # for more, see:
          # https://ertt.ca/nix/patch-nixpkgs/
          # https://juuso.dev/blogPosts/modular-neovim/modular-neovim-with-nix.html
          nixpkgs-patched = import
            ((import inputs.nixpkgs { inherit system; }).applyPatches {
              name = "nixpkgs-pr-455630";
              src = inputs.nixpkgs;
              patches = [ ./packages/trezor/455630.patch ];
            })
            {
              inherit system;
              config.permittedInsecurePackages = [ "python3.13-ecdsa-0.19.1" ];
            };
        in
        {

          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
            ];
            config = {
              permittedInsecurePackages = [ "python3.13-ecdsa-0.19.1" ];
            };
          };

          overlayAttrs = {
            inherit (config.packages)
              fstar-vscode-assistant
              libedgetpu
              passage
              trezor-agent
              trezorctl
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
            "trezorctl" = nixpkgs-patched.trezorctl;
            "trezor-agent" =
              let
                trezor-old-relaxed = pkgs.python3Packages.trezor.overridePythonAttrs (_old: {
                  pythonRelaxDeps = [ "click" ];
                });
              in
              pkgs.python3Packages.trezor-agent.override {
                trezor = trezor-old-relaxed;
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

        in
        {

          # nix run .#render-workflows
          actions-nix = {
            defaultValues = {
              jobs = {
                timeout-minutes = 30;
                runs-on = "ubuntu-latest";
              };
            };
            pre-commit.enable = true;
            workflows = {
              ".github/workflows/main.yaml" = {
                on = {
                  push.branches = [ "main" ];
                  workflow_dispatch = { };
                  pull_request = { };
                };
                jobs = {
                  nix-flake-check = {
                    steps = with inputs.actions-nix.lib.steps; [
                      actionsCheckout
                      DeterminateSystemsNixInstallerAction
                      runNixFlakeCheck
                    ];
                  };
                };
              };
            };
          };

          nixosConfigurations = {
            "muro" = inputs.nixpkgs.lib.nixosSystem muro;
            "starlabs" = inputs.nixpkgs.lib.nixosSystem starlabs;
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
