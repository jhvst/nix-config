# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  # example = pkgs.callPackage ./example { };
  bqnlsp = pkgs.callPackage ./bqnlsp { };
  bqn-vim = pkgs.callPackage ./bqn-vim { };
  savilerow = pkgs.callPackage ./savilerow { };
  nvim-bqn = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "nvim-bqn";
    version = "unstable";
    src = builtins.fetchGit {
      url = "https://git.sr.ht/~detegr/nvim-bqn";
      rev = "bbe1a8d93f490d79e55dd0ddf22dc1c43e710eb3";
    };
    meta.homepage = "https://git.sr.ht/~detegr/nvim-bqn/";
  };
}
