# NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.zip nix-shell -E '
with import <nixpkgs> {};
rec { stdenv = pkgs.clangStdenv; }
linux_latest.overrideAttrs (o: {
    nativeBuildInputs=o.nativeBuildInputs ++ [ pkg-config ncurses ];
})

#'