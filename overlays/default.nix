# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: with prev.lib; {
    himalaya = prev.himalaya.overrideAttrs (oldAttrs: rec {
      version = "0.7.3";

      src = prev.fetchFromGitHub {
        owner = "soywod";
        repo = "himalaya";
        rev = "v0.7.3";
        sha256 = "sha256-HmH4qL70ii8rS8OeUnUxsy9/wMx+f2SBd1AyRqlfKfc=";
      };
      cargoDeps = oldAttrs.cargoDeps.overrideAttrs (const {
        name = "himalaya-0.7.3-vendor.tar.gz";
        inherit src;
        outputHash = "sha256-NJFOtWlfKZRLr9vvDvPQjpT4LGMeytk0JFJb0r77bwE=";
      });

      cargoBuildFlags = [ "--features=notmuch-backend" ];

      buildInputs = oldAttrs.buildInputs ++ [ prev.notmuch ];
      buildFeatures = oldAttrs.buildFeatures ++ [ "notmuch-backend" ];
    });
  };
}
