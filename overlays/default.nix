{ inputs, ... }:
{
  modifications = final: prev: with prev.lib; {
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
