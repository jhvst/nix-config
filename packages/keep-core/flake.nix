{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/c2c0373ae7abf25b7d69b2df05d3ef8014459ea3";
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

        packages.keep-core = pkgs.buildGoModule
          rec {

            name = "keep-core";

            src = pkgs.fetchFromGitHub {
              owner = "keep-network";
              repo = name;
              rev = "v2.0.0-m6";
              hash = "sha256-XMMp1dE2BBsIqoqSl9qUUyjYwSy24fQM6WqdftgzYn8=";
            };

            vendorHash = "sha256-L+5rfneAVZkssUzpoPpc6AmgmMGkbrfQccHLg237EXo=";

          };
      };
    };
}
