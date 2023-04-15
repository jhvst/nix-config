{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "u-root";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "u-root";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-EUpBHiJ13ubxYU9p9PXrv2Rqz09W16gCOMEXylhPayo=";
  };

  vendorHash = null;

  subPackages = [
    "cmds/core/*"
  ];

  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/u-root/u-root";
    description = "A fully Go userland with Linux bootloaders! u-root can create a one-binary root file system (initramfs) containing a busybox-like set of tools written in Go.";
    license = with licenses; [ bsd3 ];
    maintainers = with maintainers; [ jhvst ];
  };
}
