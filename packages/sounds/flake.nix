{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
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

        packages.default = pkgs.symlinkJoin rec {
          sounds-script = (pkgs.writeScriptBin "sounds" (builtins.readFile ./sounds.sh)).overrideAttrs (old: {
            src = ./.;
            buildCommand = ''
              ${old.buildCommand}
              patchShebangs $out
            '';
          });

          name = "sounds";
          paths = [ sounds-script ] ++ nativeBuildInputs;
          buildInputs = with pkgs; [ makeWrapper ];
          nativeBuildInputs = with pkgs; [ jq curl unixtools.xxd binutils ];
          postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
        };
      };
    };
}
