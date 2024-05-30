{ pkgs
}:
pkgs.symlinkJoin rec {
  script = (pkgs.writeScriptBin "alsa-hwid" (builtins.readFile ./alsa-hwid.sh)).overrideAttrs (old: {
    src = ./.;
    buildCommand = ''
      ${old.buildCommand}
      patchShebangs $out
    '';
  });

  name = "alsa-hwid";
  paths = [ script ] ++ nativeBuildInputs;
  buildInputs = with pkgs; [ makeWrapper ];
  nativeBuildInputs = with pkgs; [ alsa-utils ];
  postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
}
