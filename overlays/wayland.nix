{ config
, lib
, pkgs
, ...
}:
let
  rev = "master"; # 'rev' could be a git rev, to pin the overlay.
  url = "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = (import "${builtins.fetchTarball url}/overlay.nix");
in
{
  nixpkgs.overlays = [ waylandOverlay ];
}
