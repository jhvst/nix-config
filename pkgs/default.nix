# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  # example = pkgs.callPackage ./example { };
  bqnlsp = pkgs.callPackage ./bqn-lsp { };
  bqn-vim = pkgs.callPackage ./bqn-vim { };
  savilerow = pkgs.callPackage ./savilerow { };
}
