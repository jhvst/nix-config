{ pkgs
, lib
}: pkgs.rustPlatform.buildRustPackage rec {
  name = "blutgang";
  version = "0.3.0-canary2";

  src = pkgs.fetchFromGitHub {
    owner = "rainshowerLabs";
    repo = name;
    rev = version;
    hash = "sha256-xjDieJgN7BzyCzeKMd3X7dwl/hOnqFPGCtZzlAbVGdI=";
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [ openssl ];

  cargoHash = "sha256-/MnydP0inqGHmYOiSrq90pp1nHkXtzPbzJmzbprP864=";
}
