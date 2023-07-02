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
      withNotmuchBackend = true;
    });
    ksmbd-tools = prev.ksmbd-tools.overrideAttrs (oldAttrs: {
      configureFlags = oldAttrs.configureFlags ++ [ "--with-rundir=/run" ];
    });
  };
}
