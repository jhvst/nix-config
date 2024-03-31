{ self
, config
, lib
, pkgs
, ...
}: {

  fileSystems."/etc/ssh" = lib.mkImageMediaOverride {
    fsType = "btrfs";
    device = "/dev/disk/by-label/bakhal";
    options = [ "subvolid=280" ];
    neededForBoot = true;
  };

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

  boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1; # Ubisoft Connect fix: https://www.protondb.com/app/2225070#5tJ0kpnj43
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

  users = {
    users = {
      juuso = {
        isNormalUser = true;
        uid = 1000;
        group = "juuso";
        extraGroups = [ "wheel" "networkmanager" "video" "input" ];
        openssh.authorizedKeys.keys = [
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMKgTTpGSvPG4p8pRUWg1kqnP9zPKybTHQ0+Q/noY5+M6uOxkLy7FqUIEFUT9ZS/fflLlC/AlJsFBU212UzobA= ssh@secretive.sandbox.local"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdbU8l66hVUAqk900GmEme5uhWcs05JMUQv2eD0j7MI juuso@starlabs"
        ];
        shell = pkgs.fish;
        linger = true;
        hashedPasswordFile = config.sops.secrets."users/juuso".path;
      };
      sean = {
        isNormalUser = true;
        group = "sean";
        uid = 2000;
        hashedPasswordFile = config.sops.secrets."users/sean".path;
      };
    };
    groups = {
      juuso = {
        gid = 1000;
      };
      sean = {
        gid = 2000;
      };
    };
  };
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
    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
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
    lm_sensors

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
  security.rtkit.enable = true;

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
    {
      enable = true;

      what = "/dev/disk/by-label/bakhal";
      where = "/var/lib/frigate";
      type = "btrfs";
      options = "subvolid=272";

      before = [ "frigate.service" ];
      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;

      what = "/dev/disk/by-label/nvme";
      where = "/home/juuso/Maildir";
      type = "btrfs";
      options = "noatime,subvolid=258";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;

      what = "/dev/disk/by-label/bakhal";
      where = "/var/lib/postgresql/15";
      type = "btrfs";
      options = "noatime,subvolid=282";

      wantedBy = [ "multi-user.target" ];
    }
  ];

  virtualisation.podman.enable = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
  virtualisation.podman.extraPackages = [ pkgs.cni-plugin-flannel ];

  virtualisation.containers.enable = true;
  virtualisation.containers.containersConf.cniPlugins = [ pkgs.cni-plugin-flannel ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
  };

  services.invidious = {
    enable = true;
    domain = "muro.ponkila.periferia";
    settings.db.user = "invidious";
  };

  services.frigate = {
    enable = true;
    package = pkgs.frigate;
    hostname = "muro.ponkila.intra";
    settings = {
      detectors = {
        coral = {
          type = "edgetpu";
          device = "usb";
        };
      };
      cameras = {
        piha.ffmpeg.inputs = [{
          path = "";
          roles = [ "detect" ];
        }];
      };
    };
  };
  # https://github.com/NixOS/nixpkgs/issues/188719#issuecomment-1774169734
  systemd.services.frigate.environment.LD_LIBRARY_PATH = "${pkgs.libedgetpu}/lib";
  systemd.services.frigate.serviceConfig = {
    SupplementaryGroups = "plugdev";
  };
  services.udev.packages = [ pkgs.libedgetpu ];
  users.groups.plugdev = { };

  services.photoprism = {
    enable = false;
    originalsPath = "/var/mnt/bakhal/Photos";
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

  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = muro
      netbios name = muro
      security = user
      hosts allow = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
      sean = {
        path = "/var/mnt/bakhal/samba/mount/sean";
        browseable = "yes";
        "force user" = "sean";
        "force group" = "sean";
        "read only" = "no";
      };
      juuso = {
        path = "/var/mnt/bakhal/samba/mount/juuso";
        browseable = "yes";
        "force user" = "juuso";
        "force group" = "juuso";
        "read only" = "no";
      };
    };
  };

  sops = with config.users.users; {
    defaultSopsFile = ./secrets/default.yaml;
    secrets."users/juuso" = { };
    secrets."users/sean" = { };
    secrets."frigate/piha" = { };
    secrets."mbsync/ponkila" = {
      owner = juuso.name;
      group = juuso.group;
    };
    secrets."mbsync/mail.com" = {
      owner = juuso.name;
      group = juuso.group;
    };
    secrets."mbsync/gmail" = {
      owner = juuso.name;
      group = juuso.group;
    };
    secrets."mbsync/oxford" = {
      owner = juuso.name;
      group = juuso.group;
    };
    secrets."davmail/oxford" = {
      owner = juuso.name;
      group = juuso.group;
    };
    secrets."netdata/health_alarm_notify.conf" = {
      owner = "netdata";
      group = "netdata";
    };
  };

  services.netdata = {
    enable = true;
    configDir = {
      "health_alarm_notify.conf" = config.sops.secrets."netdata/health_alarm_notify.conf".path;
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/log/smartd 0755 netdata netdata -"
  ];
  services.smartd = {
    enable = true;
    extraOptions = [
      "-A /var/log/smartd/"
      "--interval=600"
    ];
  };

  system.stateVersion = "23.11";
}
