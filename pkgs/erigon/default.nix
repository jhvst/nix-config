{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "erigon";
  version = "2.28.1";

  src = fetchFromGitHub {
    owner = "ledgerwatch";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-9vja0lm6Flzmt7FAWDRZSUdJtSDbNAh/TzQOU3min9U=";
    fetchSubmodules = true;
  };

  vendorSha256 = "sha256-fZsfRvjbjDdVj01Rm3uCxfDEk2iuIooQ1dpQ5e7hT98=";
  proxyVendor = true;

  # Build errors in mdbx when format hardening is enabled:
  #   cc1: error: '-Wformat-security' ignored without '-Wformat' [-Werror=format-security]
  hardeningDisable = [ "format" ];

  subPackages = [
    "cmd/erigon"
    "cmd/evm"
    "cmd/rpcdaemon"
    "cmd/rlpdump"
  ];

  meta = with lib; {
    homepage = "https://github.com/ledgerwatch/erigon/";
    description = "Ethereum node implementation focused on scalability and modularity";
    license = with licenses; [ lgpl3Plus gpl3Plus ];
    maintainers = with maintainers; [ d-xo happysalada ];
  };
}