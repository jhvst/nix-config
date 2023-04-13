{ fetchFromSourcehut, rustPlatform, libffi, pkg-config }:

rustPlatform.buildRustPackage {
  pname = "bqnlsp";
  version = "unstable";

  src = fetchFromSourcehut {
    owner = "~juuso";
    repo = "bqnlsp";
    rev = "47376673dbd5580924e8ed8bd5fe3622361d952b";
    sha256 = "sha256-dXbf5wZM1fa81ro/11R9Zxy+w/aikIF/71C8pWpWzkQ=";
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
