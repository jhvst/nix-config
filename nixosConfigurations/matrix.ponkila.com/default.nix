{ pkgs, lib, ... }: with lib; {

  age = {
    rekey = {
      agePlugins = [ pkgs.age-plugin-fido2-hmac ];
      hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGpEmY1YpmQephSTMBUanU54F3pT8+cclp0kaugtle7r";
    };
  };

  users.users.juuso = {
    isNormalUser = true;
    group = "juuso";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMKgTTpGSvPG4p8pRUWg1kqnP9zPKybTHQ0+Q/noY5+M6uOxkLy7FqUIEFUT9ZS/fflLlC/AlJsFBU212UzobA= ssh@secretive.sandbox.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdbU8l66hVUAqk900GmEme5uhWcs05JMUQv2eD0j7MI juuso@starlabs"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILn/9IHTGC1sLxnPnLbtJpvF7HgXQ8xNkRwSLq8ay8eJAAAADHNzaDpzdGFybGFicw== ssh:starlabs"
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
    rsync
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
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 443 8448 ];
    };
    useDHCP = false;
  };

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      entryPoints = {
        matrix_clients = {
          address = ":443";
        };
        matrix_servers = {
          address = ":8448";
        };
        metrics = {
          address = ":8082";
        };
      };
      metrics = {
        prometheus = {
          entryPoint = "metrics";
        };
      };
    };
    dynamicConfigOptions = {
      tcp = {
        routers = {
          router1 = {
            rule = "HostSNI(`matrix.ponkila.com`)";
            service = "service1";
            tls = {
              passthrough = true;
            };
          };
        };
        services = {
          service1 = {
            loadBalancer = {
              servers = [
                {
                  address = "muro.hetzner:8008";
                }
              ];
            };
          };
        };
      };
    };
  };

  services.netdata = {
    enable = true;
    configDir = {
      "go.d/prometheus.conf" = pkgs.writeText "go.d/prometheus.conf" ''
        jobs:
          - name: traefik
            url: http://localhost:8082/metrics
      '';
    };
  };

  services.getty.autologinUser = "juuso";

  system.stateVersion = "24.05";

}
