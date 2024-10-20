{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/23.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , flake-parts
    , ...
    }:

    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.flake-root.flakeModule
      ];

      perSystem = { pkgs, lib, config, system, ... }: rec {

        devShells.default = pkgs.mkShell {
          packages = packages.default.nativeBuildInputs;
        };

        packages.default = packages.keep-core;


        packages.random-beacon = pkgs.stdenv.mkDerivation {
          name = "random-beacon";

          src = builtins.fetchTarball {
            # npm view @keep-network/random-beacon@mainnet dist.tarball
            url = "https://registry.npmjs.org/@keep-network/random-beacon/-/random-beacon-2.0.0.tgz";
            sha256 = "sha256:12k40b2dc1hig10cjsg2h8nyknjpjpa5n5850nqb6dcx4f4mcx4j";
          };

          installPhase = ''
            mkdir -p $out/lib
            cp -r $src/artifacts/* $out/lib
          '';

        };

        packages.contracts = pkgs.stdenv.mkDerivation {
          name = "keep-core";

          buildInputs = with pkgs; [
            nodePackages.npm
            git
          ];

          src = pkgs.fetchFromGitHub {
            owner = "keep-network";
            repo = "keep-core";
            rev = "v2.0.0-m7";
            hash = "sha256-lRcfebsycA1Fs5zil57sZW0ll5ZRQ2May4fOfLmBogY=";
          };

          buildPhase = ''
            make get_artifacts environment=mainnet
          '';

          installPhase = ''
            mkdir -p $out/lib
            cp -r tmp/* $out/lib
          '';
        };

        packages.keep-core = pkgs.buildGoModule rec {

          name = "keep-core";

          buildInputs = with pkgs; [
            nodejs
            nodePackages.npm
          ];

          src = pkgs.fetchFromGitHub {
            owner = "keep-network";
            repo = name;
            rev = "v2.0.0-m7";
            hash = "sha256-lRcfebsycA1Fs5zil57sZW0ll5ZRQ2May4fOfLmBogY=";
          };

          preBuild = ''
            make get_artifacts environment=mainnet
          '';

          vendorHash = "sha256-ZWQmKYLZYIvbIrhUJU3S27Qmjpp3Jjchqi0Sz7CoyLk=";

        };
      };
    };
}
