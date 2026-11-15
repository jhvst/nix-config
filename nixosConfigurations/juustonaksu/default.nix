{ lib
, config
, pkgs
, inputs
, ...
}: {

  boot = {
    kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;
    kernelParams = [ "boot.shell_on_fail" ];
  };
  fileSystems = {
    "/boot" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
      neededForBoot = true;
    };
    "/nix/.rw-store" = lib.mkForce (lib.mkImageMediaOverride {
      device = "/dev/nvme0n1p3";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "noatime"
        "nofail"
        "subvol=@nix-store"
        "x-initrd.mount"
      ];
    });
    "/nix/var/nix" = lib.mkImageMediaOverride {
      device = "/dev/nvme0n1p3";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "noatime"
        "nofail"
        "subvol=@nix-var"
        "x-initrd.mount"
      ];
    };
    "/var/lib/private" = lib.mkImageMediaOverride {
      device = "/dev/nvme0n1p3";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "noatime"
        "nofail"
        "subvol=@private"
        "x-initrd.mount"
      ];
    };
  };
  monitoring = {
    enable = true;
    grafana = {
      enable = true;
      address = "127.0.0.1";
    };
    logs = true;
  };
  networking = {
    hostName = "juustonaksu";
    stevenblack.enable = true;
  };
  security.sudo = {
    enable = true;
    wheelNeedsPassword = lib.mkForce false;
  };
  services = {
    fwupd.enable = true;
    getty.autologinUser = "juuso";
    grafana = {
      settings.security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
      provision.dashboards.settings.providers = [{
        name = "default";
        options.path = pkgs.linkFarm "grafana-dashboards" [
          { name = "node-exporter.json"; path = inputs.homestaking-infra.packages.x86_64-linux.grafana-dashboard-node-exporter; }
          { name = "smartctl.json"; path = inputs.homestaking-infra.packages.x86_64-linux.grafana-dashboard-smartctl; }
        ];
      }];
    };
    nixie = {
      enable = true;
      fileServer.port = 41071;
      menus = [
        {
          name = "default";
          flakeUrl = "github:jhvst/nix-config";
          hosts = [ "muro" ];
        }
      ];
      wan = {
        enable = true;
        interface = "enp2s0";
        ipv6.enable = false;
      };
      dhcp = {
        enable = true;
        subnets = [
          {
            name = "lan";
            serve = true;
            interfaces = [ "enp1s0" ];
            ipv4 = {
              address = "192.168.25.1";
              poolStart = "192.168.25.20";
              poolEnd = "192.168.25.254";
            };
            ipv6 = {
              address = "fd00:1::1";
              managed = true;
            };
            clients = [
              {
                menu = "default";
                mac = "4c:ed:fb:73:c6:f0";
                ipv4.address = "192.168.25.10";
              }
            ];
          }
        ];
      };
    };
    openssh = {
      enable = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
      };
    };
    prometheus = let fp = config.services.prometheus.exporters; in rec {
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [
            "diskstats"
            "filesystem"
            "cpu"
            "meminfo"
            "systemd"
            "cgroups"
          ];
        };
        smartctl = {
          enable = true;
          user = "root";
          devices = [ "/dev/nvme0n1" ];
        };
      };
      scrapeConfigs =
        let
          defaultConfig = job_name: {
            inherit job_name;
            static_configs = [{ targets = [ "localhost:${port job_name}" ]; }];
          };
          overrides = { };
          port = n: toString fp.${n}.port;
          srapeConfigs' = lib.mapAttrsToList
            (job_name: _: overrides.${job_name} or (defaultConfig job_name))
            exporters; # <- exporters defined above
        in
        srapeConfigs';
    };
    refindGenerate = {
      enable = true;
      dataDir = "/var/lib/refind";
      prune = true;
      rollbacks = {
        enable = true;
        keep = 1;
      };
      where = "/dev/disk/by-uuid/A67D-268B";
      flakeUrl = "github:jhvst/nix-config?ref=router";
      hosts = [ "juustonaksu" ];
      default = "juustonaksu";
      timeout = 1;
    };
  };
  system.stateVersion = "26.11";
  systemd = {
    mounts = [
      {
        enable = true;
        what = "/dev/nvme0n1p3";
        where = "/var/lib/refind";
        options = "subvol=@refind-cache";
        type = "btrfs";
        before = [ "refind-generate.service" ];
        wantedBy = [ "multi-user.target" ];
      }
      {
        enable = true;
        what = "/dev/nvme0n1p3";
        where = "/var/lib/nixie";
        options = "subvol=@ipxe-store";
        type = "btrfs";
        wantedBy = [ "multi-user.target" ];
      }
    ];
  };
  time.timeZone = "Europe/Helsinki";
  users = {
    groups.juuso.gid = 1000;
    users.juuso = {
      isNormalUser = true;
      uid = 1000;
      group = "juuso";
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJuPW2qxz9ZvzcaO5RzcDr99t55PUBjmYC9ADX6sJhbjAAAABHNzaDo= ssh:muro"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILn/9IHTGC1sLxnPnLbtJpvF7HgXQ8xNkRwSLq8ay8eJAAAADHNzaDpzdGFybGFicw== ssh:starlabs"
      ];
    };
  };

}
