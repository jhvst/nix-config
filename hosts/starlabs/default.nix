# nix-build -A pix.ipxe amd.nix -I home-manager=https://github.com/nix-community/home-manager/archive/master.tar.gz -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.zip

{ inputs, outputs, pkgs, config, lib, ... }:

with lib; {

  imports = [
    ../../home-manager/core.nix
    ../../system/ramdisk.nix
  ];

  networking.hostName = "amd";
  time.timeZone = "Europe/Helsinki";

  boot.kernelParams = [
    "boot.shell_on_fail"

    "mitigations=off"
    "l1tf=off"
    "mds=off"
    "no_stf_barrier"
    "noibpb"
    "noibrs"
    "nopti"
    "nospec_store_bypass_disable"
    "nospectre_v1"
    "nospectre_v2"
    "tsx=on"
    "tsx_async_abort=off"
  ];
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  security.sudo = {
    enable = mkDefault true;
    wheelNeedsPassword = mkForce false;
  };
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };
  networking.firewall.enable = false;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    fuse-overlayfs
    btrfs-progs
    ksmbd-tools
    lm_sensors
    nfs-utils

    vulkan-tools
  ];

  hardware.opengl = {
    ## radv: an open-source Vulkan driver from freedesktop
    driSupport = true;
    driSupport32Bit = true;

    ## amdvlk: an open-source Vulkan driver from AMD
    extraPackages = [ pkgs.amdvlk ];
    extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  ### System APIs
  services.dbus.enable = true;

  ## Window manager
  programs.sway.enable = true;
  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';
  services.getty.autologinUser = "core";

  ## Firmware blobs
  hardware.enableRedistributableFirmware = true;

}
