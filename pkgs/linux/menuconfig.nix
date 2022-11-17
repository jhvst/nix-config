# NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.zip nix-shell
# unpackPhase && cd linux-*
# ARCH=x86 LLVM=1 LLVM_IAS=1 make defconfig
# LLVM=1 LLVM_IAS=1 make -j`nproc` bzImage
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/kernel/common-config.nix

{
    nixpkgs ? import <nixpkgs> {}
}:

{
    nixpkgs.overlays = [
      #(self: super: {
      #  mesa = super.mesa.overrideAttrs (old: {
  	  #    version = "22.2.0-rc2";
      #  });
      #})
      #(self: super: {
      #  self.stdenv = nixpkgs.llvmPackages_14.stdenv;
      #})
    ];

    linux_latest = (nixpkgs.linux_latest.override {
      stdenv = nixpkgs.fastStdenv;
    }).overrideAttrs (o: {
      nativeBuildInputs = [nixpkgs.pkg-config nixpkgs.ncurses] ++ o.nativeBuildInputs;
    });
}