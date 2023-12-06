{ self
, config
, lib
, pkgs
, ...
}: {

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

  # Allows this server to be used as a remote builder
  nix.settings.trusted-users = [
    "root"
    "@wheel"
  ];

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "enp5s0";
    # Lazy IPv6 connectivity for the container
    enableIPv6 = true;
  };
  networking.hostName = "muro";
  time.timeZone = "Europe/Helsinki";

  boot.initrd.extraFiles."/etc/resolv.conf".source = pkgs.writeText "resolv.conf" ''
    nameserver 1.1.1.1
  '';
  boot.kernelParams = [
    "boot.shell_on_fail"
    "ip=dhcp"

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
  boot.kernelPatches = [
    {
      name = "CONFIG_SMB_SERVER";
      patch = null;
      extraConfig = ''
        SMB_SERVER m
      '';
    }
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
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  users.users.juuso = {
    isNormalUser = true;
    group = "juuso";
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMKgTTpGSvPG4p8pRUWg1kqnP9zPKybTHQ0+Q/noY5+M6uOxkLy7FqUIEFUT9ZS/fflLlC/AlJsFBU212UzobA= ssh@secretive.sandbox.local"
    ];
    shell = pkgs.fish;
  };
  users.groups.juuso = { };
  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;

  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  zramSwap.memoryPercent = 100;

  security.sudo = {
    enable = lib.mkDefault true;
    wheelNeedsPassword = lib.mkForce false;
  };
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  networking.firewall.enable = false;

  ## Gaming start
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
    # discord
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
    glxinfo
    vulkan-tools
    # Upscaler
    # pkgs.vkBasalt
    # Mixer and audio control
    easyeffects
    helvum
    # pkgs.lutris
    # https://github.com/Plagman/gamescope
    gamescope
    libedgetpu
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
  services.getty.autologinUser = "juuso";

  ## Firmware blobs
  hardware.enableRedistributableFirmware = true;

  systemd.mounts = [
    {
      enable = true;

      description = "local hdd storage";

      what = "/dev/disk/by-label/bakhal";
      where = "/var/mnt/bakhal";
      options = "compress=zstd:2,noatime";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;

      description = "steamlibrary storage";

      what = "/dev/disk/by-label/SteamLibrary";
      where = "/var/mnt/SteamLibrary";
      options = "noatime";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
  ];

  virtualisation.podman.enable = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
  virtualisation.podman.extraPackages = [ pkgs.cni-plugin-flannel ];

  virtualisation.containers.enable = true;
  virtualisation.containers.containersConf.cniPlugins = [ pkgs.cni-plugin-flannel ];

  systemd.services.linger = {
    enable = true;

    requires = [ "local-fs.target" ];
    after = [ "local-fs.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        /run/current-system/sw/bin/loginctl enable-linger juuso
      '';
    };

    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.ispyagentdvr = {
    path = [ "/run/wrappers" ];
    enable = false;

    description = "ispyagentdvr";
    requires = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      User = "juuso";
      Group = "juuso";
      Type = "simple";
    };

    script = ''${pkgs.podman}/bin/podman \
      --storage-opt "overlay.mount_program=${pkgs.fuse-overlayfs}/bin/fuse-overlayfs" run \
      --replace \
      --rm \
      --rmi \
      --name ispyagentdvr \
      --network=host \
      -p 8090:8090 \
      -p 3478:3478/udp \
      -p 50000-50010:50000-50010/udp \
      -v /var/mnt/bakhal/ispyagentdvr/config:/agent/Media/XML:Z \
      -v /var/mnt/bakhal/ispyagentdvr/media:/agent/Media/WebServerRoot/Media:Z \
      -v /var/mnt/bakhal/ispyagentdvr/archive:/agent/Media/WebServerRoot/Archive:Z \
      -v /var/mnt/bakhal/ispyagentdvr/commands:/agent/Commands:Z \
      docker.io/doitandbedone/ispyagentdvr
  '';

    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.netbootxyz = {
    path = [ "/run/wrappers" ];
    enable = true;

    description = "netbootxyz";
    requires = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      User = "juuso";
      Group = "juuso";
      Type = "simple";
    };

    preStart = ''
      ${pkgs.podman}/bin/podman network create netboot || true
    '';
    script = ''${pkgs.podman}/bin/podman \
      --storage-opt "overlay.mount_program=${pkgs.fuse-overlayfs}/bin/fuse-overlayfs" run \
      --replace \
      --rm \
      --rmi \
      --net=netboot \
      --name netbootxyz \
      -v /var/mnt/bakhal/netbootxyz/config:/config:z \
      -v /var/mnt/bakhal/netbootxyz/assets/public:/assets:z \
      ghcr.io/netbootxyz/netbootxyz
    '';

    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.synapse = {
    enable = true;

    description = "Matrix homeserver";
    requires = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      User = "juuso";
      Group = "juuso";
      Type = "simple";
    };

    script = ''${pkgs.matrix-synapse}/bin/synapse_homeserver \
      -c /var/mnt/bakhal/matrix/ponkila.com/ponkila.yaml
    '';

    wantedBy = [ "multi-user.target" ];
  };

  systemd.user.services.yarr = {
    enable = true;

    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      Type = "simple";
      User = "juuso";
      Group = "juuso";
    };

    script = ''${pkgs.yarr}/bin/yarr \
      -db /var/mnt/bakhal/yarr/yarr.db \
      -addr 192.168.76.40:7070
    '';

    wantedBy = [ "default.target" ];
  };

  systemd.services.davmail = {
    enable = true;

    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      Type = "simple";
    };

    script = ''${pkgs.davmail}/bin/davmail \
      /var/mnt/bakhal/davmail/davmail.properties
    '';

    wantedBy = [ "multi-user.target" ];
  };

  fileSystems."/export/nfs" = {
    device = "/var/mnt/bakhal/nfs";
    options = [ "bind" ];
  };
  services.nfs.server = {
    enable = true;
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';
    exports = ''
      /export         *.ponkila.periferia(rw,fsid=0,no_subtree_check)
      /export/nfs     *.ponkila.periferia(rw,nohide,insecure,no_subtree_check)
    '';
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="usb",ATTRS{idVendor}=="1a6e",GROUP="juuso"
    SUBSYSTEM=="usb",ATTRS{idVendor}=="18d1",GROUP="juuso"
  '';

  system.stateVersion = "23.11";
}
