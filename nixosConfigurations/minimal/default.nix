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
  boot.initrd.network.ssh = {
    enable = true;
    authorizedKeys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMKgTTpGSvPG4p8pRUWg1kqnP9zPKybTHQ0+Q/noY5+M6uOxkLy7FqUIEFUT9ZS/fflLlC/AlJsFBU212UzobA= ssh@secretive.sandbox.local"
    ];
    hostKeys = [
      ./ssh_host_ed25519_key
    ];
  };
}
