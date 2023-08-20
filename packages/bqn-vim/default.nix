{ lib
, stdenvNoCC
, fetchFromGitHub
, mbqn
, vimUtils
}:

vimUtils.buildVimPluginFrom2Nix {
  pname = "bqn-vim";
  version = mbqn.version;

  src = mbqn.src;
  sourceRoot = "source/editors/vim";

  meta.homepage = "https://github.com/mlochbaum/BQN/editors/vim";
}
