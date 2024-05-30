{ config
, dream2nix
, lib
, ...
}:
let
  pyproject = lib.importTOML (./pyproject.toml);
in
{
  imports = [
    dream2nix.modules.dream2nix.pip
  ];

  deps = { nixpkgs, ... }: {
    inherit (nixpkgs) fetchFromGitHub;
    python = nixpkgs.python3;
  };

  inherit (pyproject.project) name version;

  mkDerivation.src = config.deps.fetchFromGitHub {
    owner = "olastor";
    repo = "age-plugin-fido2-hmac";
    rev = "v0.1.1";
    sha256 = "sha256-9tyNsCFqqd2g+p80+PNN5f/Js/sviAPAtaUF3zkG+LM=";
  };

  pip = {
    pypiSnapshotDate = "2024-01-01";
    requirementsList =
      pyproject.project.dependencies;
    flattenDependencies = true;
  };
}
