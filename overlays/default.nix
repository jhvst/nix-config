{ inputs, ... }:
{
  modifications = final: prev: with prev.lib; {
    himalaya = prev.himalaya.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ optionals prev.stdenv.hostPlatform.isDarwin [ prev.pkgs.darwin.Security ];
    });
    steam = prev.steam.override {
      # https://github.com/NixOS/nixpkgs/issues/162562#issuecomment-1229444338
      extraPkgs = pkgs: with prev.pkgs; [
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
  };
}
