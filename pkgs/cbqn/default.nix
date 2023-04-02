{ lib
, stdenv
, fetchgit
, bqn-path ? null
, mbqn-source ? null
, libffi
, pkg-config
, git
}:

stdenv.mkDerivation {
  pname = "cbqn";
  version = "0.pre+date=2022-11-27";

  src = fetchgit {
    url = "https://github.com/dzaima/CBQN";
    rev = "0023e46ab87509defe1b35e25f209f40698fe8d8";
    hash = "sha256-S1lMfoxYRepygIQLoFgROc/pqYYInpQL2LTStzyfoYw=";
    fetchSubmodules = true;
    leaveDotGit = true;
    deepClone = true;
  };

  nativeBuildInputs = [
    pkg-config
  ];

  #  dontConfigure = true;

  # TODO(@sternenseemann): allow building against dzaima's replxx fork
  buildInputs = [
    libffi
    git
  ];

  postPatch = ''
    sed -i '/SHELL =.*/ d' makefile
  '';

  makeFlags = [
    "CC=${stdenv.cc.targetPrefix}cc"
  ];

  preBuild = ''
    # Purity: avoids git downloading bytecode files
    mkdir -p build/bytecodeLocal/gen
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin/
    cp BQN -t $out/bin/
    # note guard condition for case-insensitive filesystems
    [ -e $out/bin/bqn ] || ln -s $out/bin/BQN $out/bin/bqn
    [ -e $out/bin/cbqn ] || ln -s $out/bin/BQN $out/bin/cbqn

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/dzaima/CBQN/";
    description = "BQN implementation in C";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ AndersonTorres sternenseemann synthetica shnarazk ];
    platforms = platforms.all;
  };
}
# TODO: test suite
