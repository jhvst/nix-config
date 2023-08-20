{ pkgs ? import <nixpkgs> { } }:

with pkgs; stdenv.mkDerivation {
  pname = "savilerow";
  version = "1.9.1";
  src =
    if stdenv.isDarwin
    then
      fetchTarball
        {
          url = "https://savilerow.cs.st-andrews.ac.uk/savilerow-1.9.1-mac.tgz";
          sha256 = "1v36aapnvc0lz2fcl8yn7hvn346mp8xl3zw1xmlvh8sq72a8xywb";
        }
    else
      fetchTarball
        {
          url = "https://savilerow.cs.st-andrews.ac.uk/savilerow-1.9.1-linux.tgz";
          sha256 = "14vy3iy9i7f0zb9w86qmg3i3z6lvl9bpsammbdmhf547lwr23kf1";
        };

  buildInputs = [
    jdk
  ];

  dontConfigure = true;

  buildPhase = ''
    ./compile.sh
  '';

  patchPhase = ''
    substituteInPlace ./compile.sh --replace "/bin/bash" ${stdenv.shell}
    substituteInPlace ./savilerow --replace '$DIR' "${placeholder "out"}/share"
    substituteInPlace ./savilerow --replace 'java' "${jdk}/bin/java"
  '';

  installPhase = ''
    install -Dm755 savilerow ${placeholder "out"}/bin/savilerow
    install -Dm644 savilerow.jar ${placeholder "out"}/share/savilerow.jar

    install -Dm755 bin/cadical  ${placeholder "out"}/share/bin/cadical
    install -Dm755 bin/fzn-chuffed  ${placeholder "out"}/share/bin/fzn-chuffed
    install -Dm755 bin/minion ${placeholder "out"}/share/bin/minion
    install -Dm755 bin/symmetry_detect  ${placeholder "out"}/share/bin/symmetry_detect

    install -Dm644 lib/trove.jar ${placeholder "out"}/share/lib/trove.jar
  '';
}
