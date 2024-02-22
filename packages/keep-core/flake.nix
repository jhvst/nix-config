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

        packages.keep-core = pkgs.buildGoModule rec {

          name = "keep-core";

          src = pkgs.fetchFromGitHub {
            owner = "keep-network";
            repo = name;
            rev = "v2.0.0-m7";
            hash = "sha256-lRcfebsycA1Fs5zil57sZW0ll5ZRQ2May4fOfLmBogY=";
          };

          vendorHash = "sha256-ZWQmKYLZYIvbIrhUJU3S27Qmjpp3Jjchqi0Sz7CoyLk=";

        };
      };
    };
}
