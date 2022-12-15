# nix-build -A pix.ipxe finland-north-vc.nix -I home-manager=https://github.com/nix-community/home-manager/archive/master.tar.gz -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.zip

{ system ? "aarch64-linux"
, nixpkgs ? import <nixpkgs> { }
, nixos ? import <nixpkgs/nixos> { }
}:

let

  juuso = builtins.fetchTarball "https://github.com/jhvst/nix-config/archive/refs/heads/main.zip";

  # Wireguard config
  # See: https://www.wireguard.com/quickstart/
  infra.ip = "192.168.100.99"; # Server's Wireguard address
  infra.network = "192.168.100.0/24"; # Wireguard IP space
  infra.endpoint = "example.com:51820"; # Wireguard endpoint DNS with port
  infra.privateKey = "private key of this server";
  infra.publicKey = "public key of the endpoint server";

  # Nodes which run EL and CL clients
  infra.nodes = nixpkgs.lib.concatStringsSep "," [
    "http://192.168.100.2:5052"
    "http://192.168.1.200:5052"
    "http://192.168.100.3:5055"
  ];

  # Ethereum address to receive MEV tips
  fee_recipient = "0x0000000000000000000000000000000000000000";

  nixosWNetBoot = import <nixpkgs/nixos> {

    configuration = { config, pkgs, lib, ... }: with lib; {

      imports = [
        # Home Manager manages user's packages
        (import "${juuso}/home-manager/core.nix")

        (import "${juuso}/system/netboot.nix")
        (import "${juuso}/system/ramdisk.nix")
      ];

      networking.hostName = "finland-north-vc";
      time.timeZone = "Europe/Helsinki";

      boot.kernelPackages = pkgs.linuxPackages_rpi4;
      boot.loader.raspberryPi = {
        enable = true;
        version = 4;
      };
      boot.loader.grub.enable = false;

      security.sudo = {
        enable = true;
        wheelNeedsPassword = mkForce false;
      };

      services.openssh = {
        enable = true;
        passwordAuthentication = false;
      };

      environment.systemPackages = with pkgs; [
        kexec-tools

        lighthouse
      ];

      ## allow non-free firmware blobs
      hardware.enableRedistributableFirmware = true;

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

      # systemctl enable lighthouse
      # systemctl start lighthouse
      # journalctl -u lighthouse
      systemd.services.lighthouse = {
        enable = false;

        description = "Lighthouse validator client";
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];

        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
          User = "core";
          Group = "core";
          Type = "simple";
        };

        script = ''${pkgs.lighthouse}/bin/lighthouse \
          vc --network mainnet \
          --suggested-fee-recipient ${fee_recipient} \
          --beacon-nodes ${infra.nodes} \
          --enable-doppelganger-protection \
          --builder-proposals`
        '';

      };
    };
  };

  mkNetboot = nixpkgs.pkgs.symlinkJoin {
    name = "netboot";
    paths = with nixosWNetBoot.config.system.build; [ netbootRamdisk kernel netbootIpxeScript kexecTree ];
    preferLocalBuild = true;
  };

in
{
  pix.ipxe = mkNetboot;
}
