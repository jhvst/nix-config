{ lib
, config
, pkgs
, inputs
, ...
}:

let
  bridgeNames = lib.unique (map (s: "br-${s.name}") config.services.nixie.dhcp.subnets);
in
{

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
    "/etc/ssh" = lib.mkImageMediaOverride {
      device = "/dev/nvme0n1p3";
      fsType = "btrfs";
      neededForBoot = true;
      options = [ "subvol=@openssh" ];
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
    resolvconf.useLocalResolver = true;
    firewall = {
      allowPing = false;
      allowedTCPPorts = lib.mkForce [ ];
      allowedUDPPorts = lib.mkForce [ ];
      filterForward = true;
      interfaces = lib.genAttrs bridgeNames (_: {
        allowedTCPPorts = [
          22 # SSH
          53 # DNS
          config.services.nixie.fileServer.port
        ];
        allowedUDPPorts = [
          53 # DNS
          67 # DHCP
          69 # TFTP
          547 # DHCPv6
        ];
      });
    };
    hostName = "juustonaksu";
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = config.services.nixie.wan.interface;
      forwardPorts = [
        {
          sourcePort = 32400;
          proto = "tcp";
          destination = "192.168.25.10:32400";
        }
      ];
      internalInterfaces = bridgeNames;
    };
    nftables = {
      enable = true;
      tables.mac-blocklist = {
        family = "inet";
        content = ''
          set blocked_macs {
            type ether_addr
            elements = {
              B8:3A:5A:C1:03:22, # Aruba AP (avoid old customer's HPE remote admin)
            }
          }

          chain forward {
            type filter hook forward priority filter - 1; policy accept;
            oifname "wan" ether saddr @blocked_macs counter drop
          }
        '';
      };
    };
    stevenblack.enable = true;
  };
  security.sudo = {
    enable = true;
    wheelNeedsPassword = lib.mkForce false;
  };
  services = {
    coredns = {
      enable = true;
      config = ''
        . {
          hosts {
            fallthrough
          }
          forward . tls://1.1.1.2 tls://2606:4700:4700::1112 {
            tls_servername security.cloudflare-dns.com
            health_check 5s
          }
          cache 30
          prometheus
          log
          errors
        }
      '';
    };
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
        interface = "wan";
        ipv6 = {
          enable = true;
          prefixDelegation = false;
        };
      };
      dhcp = {
        enable = true;
        subnets = [
          {
            name = "lan";
            serve = true;
            interfaces = [ "lan0" "lan1" ];
            ipv4 = {
              address = "192.168.25.1";
              dns = "192.168.25.1";
              poolEnd = "192.168.25.254";
              poolStart = "192.168.25.20";
            };
            ipv6 = {
              address = "fd00:1::1";
              managed = true;
              dns = "fd00:1::1";
              poolEnd = "fd00:1::ffff";
              poolStart = "fd00:1::1000";
            };
            clients = [
              {
                menu = "default";
                mac = "4c:ed:fb:73:c6:f0";
                ipv4.address = "192.168.25.10";
                ipv6.address = "fd00:1::10";
              }
            ];
          }
        ];
      };
    };
    openssh = {
      enable = true;
      hostKeys = [{
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }];
      openFirewall = false;
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
      enable = false;
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
    resolved.enable = false;
  };
  system.stateVersion = "26.11";
  systemd = {
    network = {
      netdevs."05-dummy-lan".netdevConfig = {
        Kind = "dummy";
        Name = "dummy-lan";
      };
      links = {
        "10-wan" = {
          matchConfig.PermanentMACAddress = "84:47:09:64:83:e6";
          linkConfig.Name = "wan";
        };
        "10-lan0" = {
          matchConfig.PermanentMACAddress = "84:47:09:64:83:e7";
          linkConfig.Name = "lan0";
        };
        "10-lan1" = {
          matchConfig.PermanentMACAddress = "00:e0:4c:b5:b0:85";
          linkConfig.Name = "lan1";
        };
      };
      networks = {
        "05-dummy-lan" = {
          matchConfig.Name = "dummy-lan";
          networkConfig.Bridge = "br-lan";
          linkConfig.RequiredForOnline = "no";
        };
        "10-lan0" = {
          matchConfig.Name = "lan0";
          networkConfig.Bridge = "br-lan";
          linkConfig = {
            ActivationPolicy = "always-up";
            RequiredForOnline = "no";
          };
        };
        "10-lan1" = {
          matchConfig.Name = "lan1";
          networkConfig.Bridge = "br-lan";
          linkConfig = {
            ActivationPolicy = "always-up";
            RequiredForOnline = "no";
          };
        };
      };
    };
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
    services = {
      nginx = {
        after = [ "wait-br-lan.service" ];
        wants = [ "wait-br-lan.service" ];
      };
      wait-br-lan = {
        description = "Wait for br-lan to be configured";
        after = [ "systemd-networkd.service" ];
        wants = [ "systemd-networkd.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --interface=br-lan:routable --timeout=30";
        };
      };
    };
  };
  time.timeZone = "Europe/Helsinki";
  users = {
    groups.juuso.gid = 1000;
    mutableUsers = false;
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
