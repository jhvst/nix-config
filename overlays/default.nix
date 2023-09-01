# This file defines overlays
{ inputs, ... }:
{
  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: with prev.lib; {
    ksmbd-tools = prev.ksmbd-tools.overrideAttrs (oldAttrs: {
      configureFlags = oldAttrs.configureFlags ++ [ "--with-rundir=/run" ];
    });
    papis-nvim-git = prev.vimExtraPlugins.papis-nvim.overrideAttrs (oldAttrs: {
    });
  };
}
