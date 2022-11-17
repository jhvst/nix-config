# NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.zip nix-shell
# NIX_PATH=nixpkgs=https://github.com/jhvst/nixpkgs/archive/refs/heads/patch-opengl.zip nix-shell
# unpackPhase && cd linux-*
# patchPhase
# make menuconfig "LLVM=1" "LLVM_IAS=1"
# make -j`nproc` menuconfig bzImage "LLVM=1" "LLVM_IAS=1"

{
    nixpkgs ? import <nixpkgs> {}
}:

{
    linux_latest = (nixpkgs.linux_latest.override {
      stdenv = nixpkgs.impureUseNativeOptimizations (
          nixpkgs.overrideInStdenv (
            nixpkgs.overrideCC nixpkgs.stdenv nixpkgs.clang_14
          ) [nixpkgs.lld_14 nixpkgs.llvmPackages_14.llvm nixpkgs.llvmPackages_14.bintools nixpkgs.llvmPackages_14.openmp]);
    }).overrideAttrs (o: {
      nativeBuildInputs = [nixpkgs.pkg-config nixpkgs.ncurses] ++ o.nativeBuildInputs;
    });
}