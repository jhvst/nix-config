{ config
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

  # Allows this server to be used as a remote builder
  nix.settings.trusted-users = [
    "root"
    "@wheel"
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
  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;

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
  programs.steam.enable = false;
  programs.gamemode = {
    enable = false;
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
  ];

  hardware.bluetooth.enable = true;

  services.pipewire.enable = true;

  ## Window manager
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
      where = "/var/lib/ipfs";
      type = "btrfs";
      options = "noatime,subvolid=267";

      wantedBy = [ "multi-user.target" ];
    }
  ];

  virtualisation.podman.enable = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
  virtualisation.podman.extraPackages = [ pkgs.cni-plugin-flannel ];

  virtualisation.containers.enable = true;
  virtualisation.containers.containersConf.cniPlugins = [ pkgs.cni-plugin-flannel ];

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
    secrets."ipfs/PrivKey" = { };
    secrets."users/juuso" = { };
    secrets."users/sean" = { };
    secrets."frigate/piha" = { };
    secrets."mbsync/ponkila" = {
      owner = juuso.name;
      inherit (juuso) group;
    };
    secrets."mbsync/mail.com" = {
      owner = juuso.name;
      inherit (juuso) group;
    };
    secrets."mbsync/gmail" = {
      owner = juuso.name;
      inherit (juuso) group;
    };
    secrets."mbsync/oxford" = {
      owner = juuso.name;
      inherit (juuso) group;
    };
    secrets."davmail/oxford" = {
      owner = juuso.name;
      inherit (juuso) group;
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

  services.kubo = {
    enable = true;
    localDiscovery = true;
    settings = {
      Addresses.API = [
        "/ip4/127.0.0.1/tcp/5001"
      ];
      Addresses.Gateway = [
        "/ip4/0.0.0.0/tcp/4737"
      ];
      API.HTTPHeaders = {
        Access-Control-Allow-Origin = [ "http://127.0.0.1:5001" "https://webui.ipfs.io" ];
        Access-Control-Allow-Methods = [ "PUT" "POST" ];
      };
      Peering = {
        Peers = [{
          ID = "12D3KooWLiaVwjwrgGbxbQ8Zk7qMNMUHhhU5KQyTh93pf1kYnXxU";
          Addrs = [ "/ip4/192.168.76.4/tcp/4001" ];
        }];
      };
    };
  };

  system.stateVersion = "23.11";
}
