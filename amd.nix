# nix-build -A pix.ipxe amd.nix -I home-manager=https://github.com/nix-community/home-manager/archive/master.tar.gz -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.zip

{ system ? "x86_64-linux"
, nixpkgs ? import <nixpkgs> { }
, nixos ? import <nixpkgs/nixos> { }
,
}:

let
  juuso = builtins.fetchTarball "https://github.com/jhvst/nix-config/archive/refs/heads/main.zip";
  nixosWNetBoot = import <nixpkgs/nixos> {

    configuration = { config, pkgs, lib, ... }: with lib; {

      nixpkgs.overlays = [
        (import "${juuso}/overlays/steam.nix")
        (import "${juuso}/overlays/mesa.nix")
      ];

      imports = [
        "${juuso}/home-manager/core.nix"

        "${juuso}/system/netboot.nix"
        "${juuso}/system/ramdisk.nix"
      ];

      networking.hostName = "nvidia";
      time.timeZone = "Europe/Helsinki";

      boot.kernelParams = [
        "boot.shell_on_fail"

        "amdgpu.ppfeaturemask=0xffffffff"

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

      ## Gaming start
      nixpkgs.config.allowUnfree = true;
      programs.steam.enable = true;
      programs.gamemode = {
        enable = true;
        settings = {
          general = {
            renice = 10;
          };

          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0;
            amd_performance_level = "high";
          };
        };
      };

      environment.systemPackages = with pkgs; [
        fuse-overlayfs
        btrfs-progs
        ksmbd-tools
        lm_sensors
        nfs-utils

        # a Steam dependancy
        libblockdev
        discord
        # Install and Update Proton-GE
        # https://github.com/GloriousEggroll/proton-ge-custom
        # README: https://github.com/AUNaseef/protonup
        # protonup --download
        protonup
        # A Vulkan and OpenGL overlay for monitoring FPS, temperatures, CPU/GPU load and more.
        # https://github.com/flightlessmango/MangoHud
        # To enable: MANGOHUD=1 MANGOHUD_CONFIG=full steam
        mangohud
        # debug utils for graphics
        # pkgs.glxinfo
        vulkan-tools
        # Upscaler
        # pkgs.vkBasalt
        # Mixer and audio control
        easyeffects
        helvum
        # pkgs.lutris
        # https://github.com/Plagman/gamescope
        gamescope
      ];

      hardware.opengl = {
        ## radv: an open-source Vulkan driver from freedesktop
        driSupport = true;
        driSupport32Bit = true;

        ## amdvlk: an open-source Vulkan driver from AMD
        extraPackages = [ pkgs.amdvlk ];
        extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
      };
      hardware.steam-hardware.enable = true;
      hardware.xpadneo.enable = true;
      hardware.bluetooth.enable = true;

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
    };
  };

  mkNetboot = nixpkgs.pkgs.symlinkJoin {
    name = "netboot";
    paths = with nixosWNetBoot.config.system.build; [ kexecTree ];
    preferLocalBuild = true;
  };

in
{ pix.ipxe = mkNetboot; }
