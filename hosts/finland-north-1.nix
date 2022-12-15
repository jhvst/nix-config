# nix-build -A pix.ipxe finland-north-1.nix -I home-manager=https://github.com/nix-community/home-manager/archive/master.tar.gz -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.zip

{ system ? "x86_64-linux"
, nixpkgs ? import <nixpkgs> { }
, nixos ? import <nixpkgs/nixos> { }
,
}:

let

  juuso = builtins.fetchTarball "https://github.com/jhvst/nix-config/archive/refs/heads/main.zip";

  # Wireguard config
  # See: https://www.wireguard.com/quickstart/
  infra.ip = "192.168.100.10"; # Server's Wireguard address
  infra.network = "192.168.100.0/24"; # Wireguard IP space
  infra.endpoint = "example.com:51820"; # Wireguard endpoint DNS with port
  infra.privateKey = "private key of this server";
  infra.publicKey = "public key of the endpoint server";

  eth1.endpoint = infra.ip;
  eth1.datadir = "/var/mnt/bcachefs/eth1";

  eth2.endpoint = infra.ip;
  eth2.datadir = "/var/mnt/bcachefs/eth2";

  mev-boost.endpoint = infra.ip;

  # Add to override package versions
  #erigon_latest = nixpkgs.callPackage (import /home/core/ponkila/overlays/erigon.nix) { };
  #lighthouse_latest = nixpkgs.callPackage (import /home/core/ponkila/overlays/lighthouse.nix) { };

  nixosWNetBoot = import <nixpkgs/nixos> {

    configuration = { config, pkgs, lib, ... }: with lib; {

      imports = [
        # Home Manager manages user's packages
        (import "${juuso}/home-manager/core.nix")

        (import "${juuso}/system/netboot.nix")
        (import "${juuso}/system/ramdisk.nix")
      ];

      networking.hostName = "finland-north-1";
      time.timeZone = "Europe/Helsinki";

      # Disk latency reduction effort
      # From https://github.com/lovesegfault/nix-config/commit/1565b732258154f6b420f2b84fad478e5cb8b84a
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
      boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_testing_bcachefs);

      # Anecdote: when running from RAM, zram helps to free allocations
      zramSwap.enable = true;
      zramSwap.algorithm = "zstd";
      zramSwap.memoryPercent = 100;

      ## Allow passwordless sudo for logged in users
      security.sudo = {
        enable = mkDefault true;
        wheelNeedsPassword = mkForce false;
      };
      services.openssh = {
        enable = true;
        passwordAuthentication = false;
      };

      environment.systemPackages = with pkgs; [
        bcachefs-tools
        btrfs-progs
        kexec-tools
        fuse-overlayfs
        lm_sensors

        lighthouse
        erigon
      ];

      # Anecdote: CL performs better when synced to Hetzner
      services.timesyncd.enable = false;
      services.chrony = {
        enable = true;
        servers = [
          "ntp1.hetzner.de"
          "ntp2.hetzner.com"
          "ntp3.hetzner.net"
        ];
      };

      # Prefer networkd, use uncached nscd
      networking.dhcpcd.enable = false;
      networking.useNetworkd = true;
      services.nscd.enableNsncd = true;

      # TODO: Configure watchdog in case server halts
      # boot.kernelModules = [ "softdog" ];
      # systemd.watchdog.device = "/dev/watchdog";
      # services.udev.extraRules = mkIf cfg.softwareWatchdog ''
      #  KERNEL=="watchdog", OWNER="${cfg.user}", GROUP="${cfg.group}", MODE="0600"
      # '';

      # Wireguard tunnel
      networking.wg-quick.interfaces = {
        wg0 = {
          address = [ "${infra.ip}/32" ];
          privateKey = infra.privateKey;

          peers = [{
            publicKey = infra.publicKey;
            allowedIPs = [ infra.network ];
            endpoint = infra.endpoint;
            persistentKeepalive = 25; # KeepAlive is useful to monitor server uptime
          }];
        };
      };

      # Ports to expose only to Wireguard tunnel
      networking.firewall.interfaces."wg0".allowedTCPPorts = [
        5052 # lighthouse
      ];

      # Network ports to open to WAN
      networking.firewall = {
        allowedTCPPorts = [ 30303 30304 42069 9000 ];
        allowedUDPPorts = [ 30303 30304 42069 9000 ];
      };

      systemd.services.var-mnt-bcachefs = {
        path = [ "/run/wrappers" ];
        enable = true;

        description = "local nvme/ssd storage";

        serviceConfig = {
          Type = "oneshot";
        };

        script = ''
          /run/current-system/sw/bin/mkdir -p /var/mnt/bcachefs
          /run/wrappers/bin/mount -t bcachefs /dev/nvme0n1:/dev/nvme1n1:/dev/sda:/dev/sdb:/dev/sdc:/dev/sdd:/dev/sde:/dev/sdf /var/mnt/bcachefs
          /run/current-system/sw/bin/chown core:core /var/mnt/bcachefs
        '';

        wantedBy = [ "multi-user.target" ];
      };

      systemd.services.erigon = {
        enable = true;

        description = "execution, mainnet, alpha";
        requires = [ "network-online.target" "var-mnt-bcachefs.mount" ];
        after = [ "network-online.target" "var-mnt-bcachefs.mount" "lighthouse.service" ];

        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
          User = "core";
          Group = "core";
          Type = "simple";
        };

        script = ''${pkgs.erigon}/bin/erigon \
        --datadir=${eth1.datadir} \
        --chain mainnet \
        --authrpc.vhosts="*" \
        --authrpc.addr ${infra.ip} \
        --authrpc.jwtsecret=${eth1.datadir}/jwt.hex \
        --metrics
      '';

        wantedBy = [ "multi-user.target" ];
      };

      systemd.services.lighthouse = {
        enable = true;

        description = "beacon, mainnet, stable";
        requires = [ "network-online.target" "var-mnt-bcachefs.mount" ];
        after = [ "network-online.target" "var-mnt-bcachefs.mount" "mev-boost.service" ];

        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
          User = "core";
          Group = "core";
          Type = "simple";
        };

        script = ''${pkgs.lighthouse}/bin/lighthouse bn \
        --datadir ${eth2.datadir} \
        --network mainnet \
        --http --http-address ${infra.ip} \
        --execution-endpoint http://${eth1.endpoint}:8551 \
        --execution-jwt ${eth2.datadir}/jwt.hex \
        --builder http://${mev-boost.endpoint}:18550 \
        --slasher --slasher-history-length 256 --slasher-max-db-size 16 \
        --prune-payloads false \
        --metrics
      '';

        wantedBy = [ "multi-user.target" ];
      };

      virtualisation.podman.enable = true;
      # dnsname allows containers to use ${name}.dns.podman to reach each other
      # on the same host instead of using hard-coded IPs.
      # NOTE: --net must be the same on the containers, and not eq "host"
      # TODO: extend this with flannel ontop of wireguard for cross-node comms
      virtualisation.podman.defaultNetwork.dnsname.enable = true;

      # Linger service allows containers on user namespace
      # to be started without an interactive shell login.
      # Unless enabled, containres will not start until
      # e.g. the user logs in via console or SSH.
      systemd.services.linger = {
        enable = true;

        requires = [ "local-fs.target" ];
        after = [ "local-fs.target" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            /run/current-system/sw/bin/loginctl enable-linger core
          '';
        };

        wantedBy = [ "multi-user.target" ];
      };

      systemd.services.mev-boost = {
        path = [ "/run/wrappers" ];
        enable = true;

        description = "MEV-boost allows proof-of-stake Ethereum consensus clients to outsource block construction";
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];

        serviceConfig = {
          Restart = "always";
          RestartSec = "6s";
          User = "core";
          Group = "core";
          Type = "simple";
        };

        preStart = "${pkgs.podman}/bin/podman stop mev-boost || true";
        script = ''${pkgs.podman}/bin/podman \
        --storage-opt "overlay.mount_program=${pkgs.fuse-overlayfs}/bin/fuse-overlayfs" run \
        --replace --rmi \
        --name mev-boost \
        -p 18550:18550 \
        docker.io/flashbots/mev-boost:latest \
        -mainnet \
        -relay-check \
        -relays ${concatStringsSep "," [
          "https://0xac6e77dfe25ecd6110b8e780608cce0dab71fdd5ebea22a16c0205200f2f8e2e3ad3b71d3499c54ad14d6c21b41a37ae@boost-relay.flashbots.net"
          "https://0xad0a8bb54565c2211cee576363f3a347089d2f07cf72679d16911d740262694cadb62d7fd7483f27afd714ca0f1b9118@bloxroute.ethical.blxrbdn.com"
          "https://0x9000009807ed12c1f08bf4e81c6da3ba8e3fc3d953898ce0102433094e5f22f21102ec057841fcb81978ed1ea0fa8246@builder-relay-mainnet.blocknative.com"
          "https://0xb0b07cd0abef743db4260b0ed50619cf6ad4d82064cb4fbec9d3ec530f7c5e6793d9f286c4e082c0244ffb9f2658fe88@bloxroute.regulated.blxrbdn.com"
          "https://0x8b5d2e73e2a3a55c6c87b8b6eb92e0149a125c852751db1422fa951e42a09b82c142c3ea98d0d9930b056a3bc9896b8f@bloxroute.max-profit.blxrbdn.com"
          "https://0x98650451ba02064f7b000f5768cf0cf4d4e492317d82871bdc87ef841a0743f69f0f1eea11168503240ac35d101c9135@mainnet-relay.securerpc.com"
          "https://0x84e78cb2ad883861c9eeeb7d1b22a8e02332637448f84144e245d20dff1eb97d7abdde96d4e7f80934e5554e11915c56@relayooor.wtf"
        ]} \
        -addr 0.0.0.0:18550
      '';

        wantedBy = [ "multi-user.target" ];
      };

      services.prometheus = {
        enable = false;
        port = 9001;
        exporters = {
          node = {
            enable = true;
            enabledCollectors = [ "systemd" ];
            port = 9002;
          };
        };
        scrapeConfigs = [
          {
            job_name = "${config.networking.hostname}";
            static_configs = [{
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
            }];
          }
          {
            job_name = "erigon";
            metrics_path = "/debug/metrics/prometheus";
            scheme = "http";
            static_configs = [{
              targets = [ "127.0.0.1:6060" "127.0.0.1:6061" "127.0.0.1:6062" ];
            }];
          }
          {
            job_name = "lighthouse";
            scrape_interval = "5s";
            static_configs = [{
              targets = [ "127.0.0.1:5054" "127.0.0.1:5064" ];
            }];
          }
        ];
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
