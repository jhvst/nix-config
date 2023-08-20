{ lib
, stdenv
, fetchFromGitHub
, nodePackages
}:

stdenv.mkDerivation rec {
  pname = "grammarly";
  version = "0.22.1";

  src = fetchFromGitHub {
    owner = "znck";
    repo = "grammarly";
    rev = "v${version}";
    hash = "sha256-ZEznR2hbi2cQZyvV5OKjHBUEPX/j1s/eMRCzvYHzySI=";
  };

  buildInputs = [ nodePackages.pnpm ];

  buildPhase = ''
    export HOME=$(pwd)
    pnpm install
    pnpm run build
  '';

  installPhase = ''
    mkdir -p $out
    cp -r extension $out
  '';

  meta = with lib; {
    description = "Grammarly for VS Code";
    homepage = "https://github.com/znck/grammarly";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
