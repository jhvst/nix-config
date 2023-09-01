{

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , flake-parts
    , ...
    }:

    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem = { pkgs, lib, config, ... }: {

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            exiftool
            imagemagick
            libjxl
            just
          ];
        };

      };

    };
}
