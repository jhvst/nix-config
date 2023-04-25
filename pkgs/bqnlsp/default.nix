{ fetchFromSourcehut, rustPlatform, lib, libffi, pkg-config }:

rustPlatform.buildRustPackage {
  pname = "bqnlsp";
  version = "unstable";

  src = fetchFromSourcehut {
    owner = "~detegr";
    repo = "bqnlsp";
    rev = "e45d20673dd1bc20572e8e74f0a3b967f7001770";
    sha256 = "sha256-cu+rJkrLevqBg63d8mlbjBTmfUJG49DgUm+TXY5LDBc=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libffi
  ];

  postPatch = ''
    cp -r BQN/help/* lsp/src/help/

    mkdir -p $out/bin/BQN-docs/src
    cp -r BQN/src/* $out/bin/BQN-docs/src/

    substituteInPlace lsp/build.rs --replace ,-rpath=$ORIGIN ""
    substituteInPlace lsp/src/bqn.rs --replace \"BQN\" \"BQN-docs\"
  '';

  cargoSha256 = "sha256-miJlL0AzMJLIgJtXfcMyCASAqwgiAJCCb7+z3dBMzpg=";

  meta.homepage = "https://git.sr.ht/~detegr/bqnlsp";
}
