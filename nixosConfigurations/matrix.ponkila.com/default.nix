{ config, pkgs, lib, ... }: with lib; {

  age = {
    rekey = {
      agePlugins = [ pkgs.age-plugin-fido2-hmac ];
      hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKaz4+XGF+ivhE1gD6tMe9oStYR4d4rPsIgDDEQ/uElM";
    };
  };

  users.users.juuso = {
    isNormalUser = true;
    group = "juuso";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMKgTTpGSvPG4p8pRUWg1kqnP9zPKybTHQ0+Q/noY5+M6uOxkLy7FqUIEFUT9ZS/fflLlC/AlJsFBU212UzobA= ssh@secretive.sandbox.local"
    ];
    shell = pkgs.fish;
  };
  users.groups.juuso = { };
  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;

  networking.hostName = "matrix";
  networking.domain = "ponkila.com";
  time.timeZone = "Europe/Helsinki";

  environment.systemPackages = with pkgs; [
    kexec-tools
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

  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        address = [ "2a01:4f9:c012:ac5b::1/64" ];
        linkConfig.RequiredForOnline = "routable";
        matchConfig.Name = "enp1s0";
        networkConfig = {
          DHCP = "ipv4";
        };
        routes = [
          {
            Gateway = "fe80::1";
          }
        ];
      };
    };
  };
  networking = {
    firewall.enable = false;
    useDHCP = false;
  };

  services.nginx = {
    enable = true;
    config = ''
      events {
        worker_connections 1024;
      }

      stream {
        upstream muro {
          server muro.ponkila.periferia:8008;
        }

        map $ssl_preread_server_name $upstream {
          hostnames;
          default muro;
        }

        server {
          listen 0.0.0.0:443;
          listen 0.0.0.0:8448;

          ssl_preread on;
          proxy_pass $upstream;
        }
      }
    '';
  };

  system.stateVersion = "24.05";

}
