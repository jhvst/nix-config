# nix-build -A pix.ipxe nvidia.nix -I home-manager=https://github.com/nix-community/home-manager/archive/master.tar.gz -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.zip

{ system ? "x86_64-linux"
, nixpkgs ? import <nixpkgs> { }
, nixos ? import <nixpkgs/nixos> { }
,
}:

let
  rev = "master"; # 'rev' could be a git rev, to pin the overlay.
  url = "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = (import "${builtins.fetchTarball url}/overlay.nix");
  ponkila = builtins.fetchTarball "https://github.com/jhvst/nix-config/archive/refs/heads/main.zip";
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  nixosWNetBoot = import <nixpkgs/nixos> {

    configuration = { config, pkgs, lib, ... }: with lib; {

      nixpkgs.overlays = [ waylandOverlay ];

      imports = [
        (import "${home-manager}/nixos")
        "${ponkila}/home-manager/core.nix"

        "${ponkila}/system/netboot.nix"
        "${ponkila}/system/ramdisk.nix"
      ];

      networking.hostName = "nvidia";
      time.timeZone = "Europe/Helsinki";

      ## Performance tweaks
      boot.kernelParams = [
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

      ## Allow passwordless sudo from nixos user
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
      # enable the RealtimeKit system service, which hands out realtime
      # scheduling priority to user processes on demand. For example, the
      # PulseAudio server uses this to acquire realtime priority.
      security.rtkit.enable = true;
      environment.systemPackages = with pkgs; [
        btrfs-progs
        kexec-tools
        lm_sensors
        nfs-utils

        # a Steam dependancy
        libblockdev
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
        # pkgs.easyeffects
        # pkgs.helvum
        # pkgs.lutris
        # https://github.com/Plagman/gamescope
        # gamescope
      ];

      # https://github.com/colemickens/nixcfg/blob/dea191cc9930ec06812d4c4d8ef0469688ddcb7e/mixins/gfx-nvidia.nix
      hardware.nvidia = {
        enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;

        open = true;
        modesetting.enable = true;
        nvidiaSettings = false;
        powerManagement.enable = false;
      };

      hardware.opengl.enable = true;
      hardware.opengl.driSupport = true;
      hardware.opengl.driSupport32Bit = true;

      ## Steam Remote Play
      ### Hardware acceleration
      # hardware.opengl.extraPackages = with pkgs; [ amdvlk ];
      # hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
      # hardware.opengl.extraPackages32 = with pkgs; [ driversi686Linux.amdvlk ];
      ### Peripherals
      #### Controllers
      hardware.steam-hardware.enable = true;
      hardware.xpadneo.enable = true;
      ##
      ##  $ bluetoothctl
      ##  [bluetooth] # power on
      ##  [bluetooth] # agent on
      ##  [bluetooth] # default-agent
      ##  [bluetooth] # scan on
      ##  ...put device in pairing mode and wait [hex-address] to appear here...
      ##  [bluetooth] # pair [hex-address]
      ##  [bluetooth] # connect [hex-address]
      hardware.bluetooth.enable = true;
      #### Audio
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
      ### System APIs
      services.dbus.enable = true;

      ## Window manager
      ## https://github.com/colemickens/nixcfg/blob/dea191cc9930ec06812d4c4d8ef0469688ddcb7e/mixins/gfx-nvidia.nix
      environment.sessionVariables = {
        WLR_DRM_NO_ATOMIC = "1";
        WLR_NO_HARDWARE_CURSORS = "1";
        LIBVA_DRIVER_NAME = "nvidia";
        MOZ_DISABLE_RDD_SANDBOX = "1";
        EGL_PLATFORM = "wayland";
      };
      programs.sway.enable = true;
      programs.sway.extraOptions = [
        "--unsupported-gpu"
      ];
      services.getty.autologinUser = "core";

      ## Firmware blobs
      hardware.enableRedistributableFirmware = true;
      systemd.services.proton-ge = {
        enable = false;

        description = "Downloads the latest Proton-GE for Steam";
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = ''protonup --download -o /home/nixos -y'';
        };

        wantedBy = [ "multi-user.target" ];
      };
    };
  };

  mkNetboot = nixpkgs.pkgs.symlinkJoin {
    name = "netboot";
    paths = with nixosWNetBoot.config.system.build; [ netbootRamdisk kernel netbootIpxeScript kexecTree ];
    preferLocalBuild = true;
  };

in
{ pix.ipxe = mkNetboot; }
