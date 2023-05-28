{ config, pkgs, lib, ... }: with lib; {

  documentation.enable = false;

  boot.initrd.availableKernelModules = [ "squashfs" "overlay" "e1000" ];
  boot.initrd.kernelModules = [ "loop" "overlay" ];

  boot.kernelParams = [
    "boot.shell_on_fail"
  ];

  fileSystems."/" = lib.mkImageMediaOverride {
    fsType = "tmpfs";
    options = [ "mode=0755" ];
  };
  boot.loader.grub.enable = false;
  boot.initrd.network.enable = true;
}
