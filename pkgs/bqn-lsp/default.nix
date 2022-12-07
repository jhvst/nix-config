{ fetchFromSourcehut, lib, rustPlatform, libffi, pkg-config, stdenv, libiconv }:

rustPlatform.buildRustPackage {
  pname = "bqnlsp";
  version = "unstable";

  src = fetchFromSourcehut {
    owner = "~detegr";
    repo = "bqnlsp";
    rev = "4057b10672996b649a0ce44822ea8aa235776bca";
    sha256 = "sha256-fkR4N1M6bQsHVHcJKREOLtfNmWA5rUsn5xzv5YjZn8g=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    pkg-config
  ];

  postPatch = ''
    cp -r BQN/help/* lsp/src/help/

    mkdir -p $out/bin/BQN-docs/src
    cp -r BQN/src/* $out/bin/BQN-docs/src/

    substituteInPlace lsp/build.rs --replace ,-rpath=$ORIGIN ""
    substituteInPlace lsp/src/bqn.rs --replace \"BQN\" \"BQN-docs\"
  '';


  buildInputs = [
    libffi
    libiconv
  ];

  cargoSha256 = "sha256-ltGdLdTg1OsnULluU7v5MQfCWT5g/tyMZkPxWLzwlF8=";

  meta.homepage = "https://git.sr.ht/~detegr/bqnlsp";
}
