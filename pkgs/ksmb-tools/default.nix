{ lib, stdenv, fetchFromGitHub
, pkg-config, autoreconfHook
, glib, libnl
}:

stdenv.mkDerivation rec {
  pname = "ksmbd-tools";
  version = "3.4.5";

  src = fetchFromGitHub {
    owner = "cifsd-team";
    repo = pname;
    rev = version;
    sha256 = "sSCLXNdVUAdk+GnFlVx/BsAzyfz0KDdugJ1isrOztgs=";
  };

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
  ];

  buildInputs = [
    glib
    libnl
  ];

  meta = with lib; {
    description = "ksmbd kernel server userspace utilities";
    homepage = "https://www.kernel.org/doc/html/latest/filesystems/cifs/ksmbd.html";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ jhvst ];
    platforms = platforms.linux;
  };
}