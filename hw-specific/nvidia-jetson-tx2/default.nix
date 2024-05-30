{ pkgs
, ...
}:

{

  nixpkgs.overlays = [
    (_: prev: {
      linuxPackagesFor = kernel: (prev.linuxPackagesFor kernel).extend (_: _: {
        ati_drivers_x11 = null;
      });
    })
  ];

  boot.kernelPackages =
    pkgs.linuxPackagesFor (pkgs.linuxKernel.manualConfig {
      inherit (pkgs) stdenv lib;
      version = "4.9.309";
      modDirVersion = "4.9.309";
      src = pkgs.fetchFromGitHub {
        owner = "skiffos";
        repo = "linux";
        rev = "skiff-jetson-4.9.x";
        sha256 = "2L9XJoUUYPkRO+yZ7el2lApNE0tFM9slIRJAKklELdo=";
      };
      configfile = ./kconfig;
      allowImportFromDerivation = true;
    });

}
