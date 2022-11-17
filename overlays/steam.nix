# https://github.com/NixOS/nixpkgs/issues/162562#issuecomment-1229444338
self: super: {
  steam = super.steam.override {
    extraPkgs = pkgs: with pkgs; [
      xorg.libXcursor
      xorg.libXi
      xorg.libXinerama
      xorg.libXScrnSaver
      libpng
      libpulseaudio
      libvorbis
      stdenv.cc.cc.lib
      libkrb5
      keyutils
    ];
  };
  # TODO: the following is simpler, and should work as well
  # steam = super.steam.overrideAttrs (old: {
  #   extraPkgs = old.extraPkgs ++ [ super.libkrb5 super.keyutils ];
  # });
}
