# nix-build -A pix.ipxe nvidia.nix -I home-manager=https://github.com/nix-community/home-manager/archive/master.tar.gz -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.zip

{ system ? "x86_64-linux"
, nixpkgs ? import <nixpkgs> { }
, nixos ? import <nixpkgs/nixos> { }
,
}:

let
  juuso = builtins.fetchTarball "https://github.com/jhvst/nix-config/archive/refs/heads/main.zip";
  wayland = builtins.fetchTarball "https://github.com/nix-community/nixpkgs-wayland/archive/master.tar.gz";
  nixosWNetBoot = import <nixpkgs/nixos> {

    configuration = { config, pkgs, lib, ... }: with lib; {

      nixpkgs.overlays = [
        (import "${juuso}/overlays/mesa.nix")
        (import "${wayland}/overlay.nix")
      ];

      imports = [
        "${juuso}/home-manager/core.nix"

        "${juuso}/system/netboot.nix"
        "${juuso}/system/ramdisk.nix"
      ];

      boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

      boot.kernelPatches = [{
        name = "kernel network config";
        patch = null;
        extraConfig = ''
          TLS y
          IP_PNP y
          IP_PNP_DHCP y
          IP_PNP_BOOTP y
          IP_PNP_RARP y
          DNS_RESOLVER y
          NET_SELFTESTS y
          BLK_DEV_LOOP y
          MII y
          MACSEC y
          MDIO y
          AMD_XGBE y
          AQTION y
          BNX2 y
          BNX2X y
          E1000 y
          E1000E y
          IGB y
          IXGB y
          ICE y
          8139CP y
          8139TOO y
          PHYLIB y
          FIXED_PHY y
          MDIO_DEVICE y
          MDIO_BUS y
          FWNODE_MDIO y
          ACPI_MDIO y
          MDIO_DEVRES y
          KEYBOARD_ATKBD y
          SERIO y
          SERIO_I8042 y
          SERIO_PCIPS2 y
          SERIO_LIBPS2 y
          VIRTIO_CONSOLE y
          I2C y
          ACPI_I2C_OPREGION y
          I2C_ALGOBIT y
          PPS y
          PTP_1588_CLOCK y
          PTP_1588_CLOCK_OPTIONAL y
          HID y
          HID_GENERIC y
          USB_HID y
          USB_COMMON y
          USB y
          USB_XHCI_HCD y
          USB_EHCI_HCD y
          USB_EHCI_PCI y
          USB_OHCI_HCD y
          USB_UHCI_HCD y
          TYPEC y
          RTC_I2C_AND_SPI y
          VIRTIO y
          VIRTIO_INPUT y
          OVERLAY_FS y
          SQUASHFS y
          CRYPTO_AEAD y
          CRYPTO_GF128MUL y
          CRYPTO_NULL y
          CRYPTO_GCM y
          CRYPTO_CTR y
          CRYPTO_CRC32C y
          CRYPTO_GHASH y
          CRYPTO_AES y
          CRYPTO_LIB_AES y
          LIBCRC32C y
        '';
      }];

      networking.hostName = "nvidia";
      time.timeZone = "Europe/Helsinki";

      ## Performance tweaks
      boot.kernelParams = [
        "boot.shell_on_fail"
        "ip=dhcp"

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
        easyeffects
        helvum
        # pkgs.lutris
        # https://github.com/Plagman/gamescope
        # Note: currently borked with wayland overlay
        # gamescope
      ];

      # https://github.com/colemickens/nixcfg/blob/dea191cc9930ec06812d4c4d8ef0469688ddcb7e/mixins/gfx-nvidia.nix
      services.xserver.videoDrivers = [ "nvidia" "modesetting" ];
      hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
      hardware.nvidia.modesetting.enable = true;

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
    paths = with nixosWNetBoot.config.system.build; [ netbootRamdisk kernel netbootIpxeScript ];
    preferLocalBuild = true;
  };

in
{ pix.ipxe = mkNetboot; }
