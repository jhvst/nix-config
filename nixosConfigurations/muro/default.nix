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
  nix.settings.secret-key-files = [ "/var/mnt/bakhal/garage/cache-priv-key" ];

  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        linkConfig.RequiredForOnline = "routable";
        matchConfig.Name = "enp5s0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
        dns = [ "127.0.0.1:1053" ];
        address = [ "192.168.17.10/24" ]; # static IP
      };
    };
  };
  networking = {
    hostName = "muro";
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp5s0";
      # Lazy IPv6 connectivity for the container
      enableIPv6 = true;
    };
    nameservers = [ "127.0.0.1:1053" ];
    firewall.enable = false;
    wg-quick.interfaces = {
      ponkila.configFile = config.sops.secrets."wireguard/ponkila".path;
    };
    useDHCP = false;
  };
  time.timeZone = "Europe/Helsinki";
  services.coredns = {
    enable = true;
    config = ''
      .:1053 {
        forward . 1.1.1.1 {
          health_check 5s
        }
        cache 30
      }
    '';
  };

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

  users = {
    users = {
      juuso = {
        isNormalUser = true;
        uid = 1000;
        group = "juuso";
        extraGroups = [ "wheel" "video" "input" "acme" "aria2" ];
        openssh.authorizedKeys.keys = [
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILn/9IHTGC1sLxnPnLbtJpvF7HgXQ8xNkRwSLq8ay8eJAAAADHNzaDpzdGFybGFicw== ssh:starlabs"
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

  security = {
    acme = {
      acceptTerms = true;
      defaults.email = "juuso@ponkila.com";
      certs."matrix.ponkila.com" = {
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets."domain/cloudflare".path;
      };
    };
    sudo = {
      enable = true;
      wheelNeedsPassword = lib.mkForce false;
    };
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

  programs.gamemode.settings = {
    general = {
      renice = 10;
    };
    gpu = {
      apply_gpu_optimisations = "accept-responsibility";
      gpu_device = 0;
      amd_performance_level = "high";
    };
  };

  environment.systemPackages = with pkgs; [
    garage_2
    w3m
  ];

  hardware.bluetooth.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  services.getty.autologinUser = "juuso";

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
    {
      enable = true;

      what = "/dev/disk/by-label/bakhal";
      where = "/var/lib/acme";
      type = "btrfs";
      options = "noatime,subvolid=283";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;

      what = "/dev/disk/by-label/bakhal";
      where = "/var/lib/aria2";
      type = "btrfs";
      options = "noatime,subvolid=284,compress=zstd";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;

      what = "/dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5SSNF0R201250K";
      where = "/var/mnt/SteamLibrary";
      type = "btrfs";
      options = "noatime";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;

      what = "/dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5SSNF0R201250K";
      where = "/home/juuso/My Games";
      type = "btrfs";
      options = "subvol=GameSaves/Firaxis";

      wantedBy = [ "multi-user.target" ];
    }
  ];

  services.plex = {
    enable = true;
    group = "juuso";
    user = "juuso";
    dataDir = "/var/mnt/bakhal/Plex/.config/Library/Application Support";
  };

  services.aria2 = {
    enable = true;
    rpcSecretFile = config.sops.secrets."aria2/rpc".path;
    settings = {
      console-log-level = "warn";
      listen-port = [{ from = 6881; to = 6999; }];
      max-concurrent-downloads = 100;
      openPorts = true;
      remote-time = true;
      rpc-listen-port = 6800;
      seed-ratio = 3.0;
    };
  };

  services.frigate = {
    enable = false;
    package = pkgs.frigate;
    hostname = "muro.ponkila.intra";
    settings = {
      detectors = {
        coral = {
          type = "edgetpu";
          device = "usb";
        };
      };
      cameras = { };
    };
  };
  # https://github.com/NixOS/nixpkgs/issues/188719#issuecomment-1774169734
  #systemd.services.frigate.environment.LD_LIBRARY_PATH = "${pkgs.libedgetpu}/lib";
  #systemd.services.frigate.serviceConfig = {
  #  SupplementaryGroups = "plugdev";
  #};
  #services.udev.packages = [ pkgs.libedgetpu ];
  #users.groups.plugdev = { };

  services.photoprism = {
    enable = false;
    originalsPath = "/var/mnt/bakhal/Photos";
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
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "muro";
        "netbios name" = "muro";
        "hosts allow" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        security = "user";
      };
      sean = {
        path = "/var/mnt/bakhal/samba/mount/sean";
        browseable = "yes";
        "force user" = "sean";
        "force group" = "sean";
        "read only" = "no";
      };
      juuso = {
        "force group" = "juuso";
        "force user" = "juuso";
        "fruit:delete_empty_adfiles" = "yes";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:nfs_aces" = "no";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "read only" = "no";
        "vfs objects" = "fruit streams_xattr";
        browseable = "yes";
        path = "/var/mnt/bakhal/samba/mount/juuso";
      };
    };
  };

  sops = with config.users.users; {
    defaultSopsFile = ./secrets/default.yaml;
    secrets."aria2/rpc" = {
      owner = aria2.name;
      inherit (aria2) group;
    };
    secrets."domain/cloudflare" = { };
    secrets."ipfs/PrivKey" = { };
    secrets."users/juuso" = { };
    secrets."users/sean" = { };
    secrets."frigate/piha" = { };
    secrets."wireguard/ponkila" = { };
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

  system.stateVersion = "25.11";
}
