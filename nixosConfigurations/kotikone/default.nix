{ config, pkgs, lib, ... }: with lib; {

  networking.hostName = "kotikone";
  time.timeZone = "Europe/Helsinki";
  services.xserver.xkb.layout = "fi";
  i18n.defaultLocale = "fi_FI.UTF-8";

  users.users.kotikone = {
    isNormalUser = true;
    group = "kotikone";
    extraGroups = [ "wheel" "video" "input" "scanner" "lp" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMKgTTpGSvPG4p8pRUWg1kqnP9zPKybTHQ0+Q/noY5+M6uOxkLy7FqUIEFUT9ZS/fflLlC/AlJsFBU212UzobA= ssh@secretive.sandbox.local"
    ];
  };
  users.groups.kotikone = { };

  services.xserver.enable = true;
  services.xserver.displayManager.sddm = {
    enable = true;
    settings = {
      Autologin = {
        Session = "plasma.desktop";
        User = "kotikone";
      };
    };
  };
  services.xserver.desktopManager.plasma5.enable = true;

  programs.firefox = {
    enable = true;
    languagePacks = [ "fi" ];
  };

  hardware.sane.enable = true;
  services.ipp-usb.enable = true;
  services.printing = {
    enable = true;
    drivers = [ pkgs.cnijfilter2 ];
  };
  hardware.printers = {
    ensurePrinters = [
      {
        name = "MG5700";
        location = "Home";
        deviceUri = "usb://Canon/MG5700%20series?serial=204EE0";
        model = "${pkgs.cnijfilter2}/share/cups/model/canonmg5700.ppd";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];
    ensureDefaultPrinter = "MG5700";
  };
  environment.systemPackages = with pkgs; [
    xsane
    vlc
  ];

  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;

  boot.kernelPatches = [
    {
      name = "enable NICs";
      patch = null;
      extraConfig = ''
        ETHERNET y
        IGB y
        IXGBE y
        NET_VENDOR_INTEL y
      '';
    }
    {
      name = "network config base";
      patch = null;
      extraConfig = ''
        # IP Configuration and DNS
        IP_PNP y
        IP_PNP_DHCP y
        IP_PNP_BOOTP y
        IP_PNP_RARP y
        DNS_RESOLVER y

        # Transport Layer Security
        TLS y
        CRYPTO_AEAD y
        CRYPTO_NULL y
        CRYPTO_GCM y
        CRYPTO_CTR y
        CRYPTO_CRC32C y
        CRYPTO_GHASH y
        CRYPTO_AES y
        CRYPTO_LIB_AES y

        # Misc
        PHYLIB y

        # PTP clock
        PPS y
        PTP_1588_CLOCK y

        # Filesystem
        BLK_DEV_LOOP y
        LIBCRC32C y
        OVERLAY_FS y
        SQUASHFS y

        # USB and HID
        HID y
        HID_GENERIC y
        KEYBOARD_ATKBD y
        TYPEC y
        USB y
        USB_COMMON y
        USB_EHCI_HCD y
        USB_EHCI_PCI y
        USB_HID y
        USB_OHCI_HCD y
        USB_UHCI_HCD y
        USB_XHCI_HCD y
      '';
    }
  ];

  ## Performance tweaks
  boot.kernelParams = [
    "boot.shell_on_fail"
    "ip=dhcp"
  ];

  ## Allow passwordless sudo from nixos user
  security.sudo = {
    enable = mkDefault true;
    wheelNeedsPassword = mkForce false;
  };
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  hardware.opengl.enable = true;

  # https://github.com/colemickens/nixcfg/blob/dea191cc9930ec06812d4c4d8ef0469688ddcb7e/mixins/gfx-nvidia.nix
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.nvidiaSettings = true;
  hardware.nvidia.open = true;

  #### Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  ### System APIs
  services.dbus.enable = true;

  system.build.squashfs = pkgs.linkFarm "squashfs" [
    {
      name = "squashfs.img";
      path = "${config.system.build.squashfsStore}";
    }
    {
      # NOTE: this is only the initial ramdisk (12MB)
      name = "initrd.zst";
      path = "${config.system.build.initialRamdisk}/initrd";
    }
    {
      name = "bzImage";
      path = "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}";
    }
  ];

  system.stateVersion = "23.11";
}
