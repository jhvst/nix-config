{ pkgs, config, ... }:
{

  boot = {
    initrd = {
      kernelModules = [ "amdgpu" "btrfs" ];
      luks.fido2Support = true;
    };
    kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1; # Ubisoft Connect fix: https://www.protondb.com/app/2225070#5tJ0kpnj43
    kernelParams = [
      "boot.shell_on_fail"
    ];
    kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  # sops keys
  fileSystems."/home/juuso/.ssh" = {
    device = "/dev/sda2";
    fsType = "btrfs";
    options = [ "subvolid=260" ];
    neededForBoot = true;
  };

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "IBMPlexMono" ]; })
      departure-mono
    ];
  };

  home-manager.users.juuso = {

    programs.obs-studio = {
      enable = false;
      plugins = [ pkgs.obs-studio-plugins.wlrobs ];
    };

    programs.foot = {
      enable = true;
      settings = {
        main = {
          term = "xterm-256color";
          font = "BlexMono Nerd Font Mono:size=11";
        };
        mouse = {
          hide-when-typing = "yes";
        };
        url = {
          launch = "${pkgs.nix} run nixpkgs#firefox -- ";
        };
      };
    };

    programs.yambar = {
      enable = true;
      settings =
        let
          green = "2ecc71ff";
          red = "dd5555ff";
        in
        {
          bar = {
            font = "Departure Mono:style=Regular";
            location = "top";
            height = 26;
            background = "00000066";

            left = [
              {
                i3 = rec {
                  right-spacing = 6;
                  persistent = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
                  content =
                    let
                      workspace = n: {
                        name = n;
                        value = let s = { text = if n == "10" then "0" else n; margin = 8; }; in {
                          map = {
                            default.string = s;
                            conditions = {
                              empty.string = s // {
                                foreground = "ffffff77";
                              };
                              focused.string = s // {
                                deco.underline = {
                                  size = 2;
                                  color = "ffffffff";
                                };
                              };
                              urgent.string = s // {
                                deco.background.color = "dd5555ff";
                              };
                            };
                          };
                        };
                      };
                    in
                    builtins.listToAttrs (map workspace persistent);
                };
              }
            ];
            center = [
              {
                label = {
                  content = [{
                    string.text = config.networking.hostName;
                  }];
                };
              }
            ];
            right = [
              {
                script = {
                  path = pkgs.writeScript "test.sh" ''
                    #!${pkgs.stdenv.shell}
                    STATUS=$(${pkgs.curl}/bin/curl -s -m 3 http://192.168.100.10:5052/eth/v1/node/syncing | ${pkgs.jq}/bin/jq '.data.is_optimistic')
                    echo "test|string|$STATUS"
                    echo ""
                  '';
                  poll-interval = 11000;
                  args = [ ];
                  content = [{
                    map = let host = "Pα"; in {
                      default.string = {
                        deco.background.color = red;
                        text = host;
                      };
                      conditions = {
                        "test == false" = {
                          string = {
                            deco.background.color = green;
                            text = host;
                          };
                        };
                      };
                    };
                  }];
                };
              }
              {
                script = {
                  path = pkgs.writeScript "test.sh" ''
                    #!${pkgs.stdenv.shell}
                    STATUS=$(${pkgs.curl}/bin/curl -s -m 3 http://192.168.100.33:5052/eth/v1/node/syncing | ${pkgs.jq}/bin/jq '.data.is_optimistic')
                    echo "test|string|$STATUS"
                    echo ""
                  '';
                  poll-interval = 11000;
                  args = [ ];
                  content = [{
                    map = let host = "Dα"; in {
                      default.string = {
                        deco.background.color = red;
                        text = host;
                      };
                      conditions = {
                        "test == false" = {
                          string = {
                            deco.background.color = green;
                            text = host;
                          };
                        };
                      };
                    };
                  }];
                };
              }
              {
                mem = {
                  poll-interval = 2500;
                  content = [{
                    string.text = "{free:mb}MB";
                  }];
                };
              }
              {
                battery = {
                  name = "BAT0";
                  poll-interval = 30000;
                  content = [
                    {
                      string.text = "{capacity}%";
                    }
                  ];
                };
              }
              {
                clock = {
                  time-format = "%H:%M:%S";
                  date-format = "%A %-d of %b %Y %z";
                  content = [
                    {
                      string.text = "{date}";
                    }
                    {
                      string.text = "{time}";
                    }
                  ];
                };
              }
            ];
          };
        };
    };
    programs.swaylock.enable = true;

    wayland.windowManager.sway = {
      enable = true;
      config = {
        terminal = "foot";
        bars = [{
          command = "${pkgs.yambar}/bin/yambar";
          fonts = {
            names = [ "Departure Mono" ];
            size = 11.0;
          };
        }];
        input = {
          "type:keyboard" = {
            xkb_layout = "us,fi";
          };
          "type:touchpad" = {
            tap = "disabled";
            natural_scroll = "enabled";
          };
          "type:mouse" = {
            natural_scroll = "enabled";
          };
        };
      };
    };

    programs.gpg = with config.home-manager.users.juuso; {
      enable = true;
      homedir = "${home.homeDirectory}/.gnupg/trezor";
      settings = {
        agent-program = "${pkgs.trezor_agent}/bin/trezor-gpg-agent";
        default-key = "Juuso Haavisto <juuso@ponkila.com>";
      };
    };

    programs.password-store = {
      enable = true;
      package = pkgs.passage;
      settings = {
        PASSAGE_DIR = "/run/media/juuso/passage";
        PASSAGE_IDENTITIES_FILE = "/run/secrets/passage";
        PASSAGE_RECIPIENTS = "age1ef70t0zmlcvpe4ppwfdza7qpv2uakq9c9ldrv0y9zfnvdka7acnsxkkmzl age12lz3jyd2weej5c4mgmwlwsl0zmk2tdgvtflctgryx6gjcaf3yfsqgt7rnz";
        PASSWORD_STORE_CLIP_TIME = "60";
      };
    };

    programs.ssh = {
      enable = true;
      hashKnownHosts = true;
      matchBlocks = {
        "*" = {
          identityFile = "~/.ssh/id_ed25519_sk_rk_starlabs";
        };
      };
    };

  };

  system.etc.overlay.mutable = false;

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    links = {
      "20-iwd" = {
        matchConfig.Type = "wlan";
        linkConfig = {
          Name = "wlan0";
          MACAddressPolicy = "random";
        };
      };
    };
    netdevs = {
      "99-ath0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "ath0";
        };
        wireguardConfig.PrivateKeyFile = config.sops.secrets."wireguard/ath0".path;
        wireguardPeers = [{
          PublicKey = "TCLvI4LY2KfU5eXdbcFYC+PCX1OzrB8JX2hOdtfZ8WE=";
          AllowedIPs = [
            "192.168.17.0/24"
            "192.168.76.0/24"
            "2001:470:28:6a9:8000::0/65"
          ];
          Endpoint = "ath0.ponkila.intra:51820";
        }];
      };
      "99-dinar" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "dinar";
        };
        wireguardConfig.PrivateKeyFile = config.sops.secrets."wireguard/dinar".path;
        wireguardPeers = [{
          PublicKey = "s7XsWWxjl8zi6DTx4KkhjmI1jVseV9KVlc+cInFNyzE=";
          AllowedIPs = [ "192.168.100.0/24" ];
          Endpoint = [ "dinar.majbacka.intra:51820" ];
          PersistentKeepalive = 25;
        }];
      };
      "99-qmi0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "qmi0";
        };
        wireguardConfig.PrivateKeyFile = config.sops.secrets."wireguard/qmi0".path;
        wireguardPeers = [{
          PublicKey = "EuwxoYfYJaHX37CdjJgGpYTBCwUee/vZLZdn38M1imc=";
          AllowedIPs = [ "192.168.77.0/24" "192.168.18.0/24" ];
          Endpoint = "qmi0.ponkila.intra:51820";
          PersistentKeepalive = 25;
        }];
      };
    };
    networks = {
      "10-wan" = {
        matchConfig.Name = "wlan0";
        dhcpV4Config.Anonymize = true;
        networkConfig = {
          DHCP = "ipv4";
          DNSOverTLS = true;
          IPv6AcceptRA = true;
        };
        dns = [ "127.0.0.1:1053" ];
        linkConfig.RequiredForOnline = "routable";
      };
      "20-usb" = {
        matchConfig.Name = "enp2s0f4u2u2";
        networkConfig = {
          DHCP = "ipv4";
          IPMasquerade = "ipv4";
        };
        dns = [ "1.1.1.1" ];
        linkConfig.ActivationPolicy = "manual";
      };
      "99-ath0" = {
        matchConfig.Name = "ath0";
        address = [ "192.168.76.4/32" "2001:470:28:6a9:8000::4/128" ];
        dns = [ "192.168.76.1" "2001:470:28:6a9:8000::1" ];
        domains = [ "ponkila.periferia" ];
        linkConfig.ActivationPolicy = "manual";
        routes = [
          {
            Gateway = "192.168.76.1";
            GatewayOnLink = true;
            Destination = "192.168.76.0/24";
          }
          {
            Gateway = "192.168.76.1";
            GatewayOnLink = true;
            Destination = "192.168.17.0/24";
          }
          {
            Gateway = "2001:470:28:6a9:8000::1";
            GatewayOnLink = true;
            Destination = "2001:470:28:6a9:8000::0/65";
          }
        ];
      };
      "99-dinar" = {
        matchConfig.Name = "dinar";
        address = [ "192.168.100.101/32" ];
        linkConfig.ActivationPolicy = "manual";
        routes = [{
          Gateway = "192.168.100.1";
          GatewayOnLink = true;
          Destination = "192.168.100.0/24";
        }];
      };
      "99-qmi0" = {
        matchConfig.Name = "qmi0";
        address = [ "192.168.77.200/32" ];
        linkConfig.ActivationPolicy = "manual";
        routes = [
          {
            Gateway = "192.168.77.1";
            GatewayOnLink = true;
            Destination = "192.168.77.0/24";
          }
          {
            Gateway = "192.168.77.1";
            GatewayOnLink = true;
            Destination = "192.168.18.0/24";
          }
        ];
      };
    };
  };
  networking = {
    domain = "juuso.dev";
    firewall.interfaces."ath0".allowedTCPPorts = [ 4001 ];
    hostName = "starlabs";
    nameservers = [ "127.0.0.1:1053#starlabs.juuso.dev" ];
    nftables.enable = true;
    stevenblack.enable = true;
    useDHCP = false;
    wireless.iwd.enable = true;
  };
  services.resolved.dnsovertls = "opportunistic";
  services.coredns = {
    enable = true;
    config = ''
      tls://.:1053 {
        tls /var/lib/acme/starlabs.juuso.dev/cert.pem /var/lib/acme/starlabs.juuso.dev/key.pem
        import ../../run/secrets/coredns/rewrites
        forward . tls://1.1.1.1 {
          tls_servername cloudflare-dns.com
          health_check 5s
        }
        cache 30
      }
    '';
  };
  systemd.services."coredns".serviceConfig.Group = "acme";

  time.timeZone = "Europe/London";

  users = {
    mutableUsers = false;
    users.juuso = {
      isNormalUser = true;
      uid = 1000;
      group = "juuso";
      extraGroups = [ "wheel" "video" "input" "ipfs" "acme" ];
      openssh.authorizedKeys.keys = [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMKgTTpGSvPG4p8pRUWg1kqnP9zPKybTHQ0+Q/noY5+M6uOxkLy7FqUIEFUT9ZS/fflLlC/AlJsFBU212UzobA= ssh@secretive.sandbox.local"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDq7kUCTPNw8SPNbGsNslECroKNljRGZk9fIBIEzrvI epsilon"
      ];
      shell = pkgs.fish;
    };
    groups.juuso = {
      gid = 1000;
    };
  };

  security = {
    acme = {
      acceptTerms = true;
      defaults.email = "juuso@ponkila.com";
      certs."starlabs.juuso.dev" = {
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets."domain/cloudflare/juuso.dev".path;
      };
    };
    sudo.enable = true;
    pam.services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
    };
    rtkit.enable = true;
    polkit.enable = true;
  };

  environment = {
    shells = [ pkgs.fish ];
    systemPackages = with pkgs; [
      age-plugin-fido2-hmac
      beeper
      btrfs-progs
      cryptsetup
      file
      gnupg
      iamb # matrix client
      pinentry-curses
      sioyek
      sops
      trezor-agent
      trezorctl
      waypipe
      wl-clipboard
      xdg-utils # open command
      xorg.xkbcomp
      yazi
      yubikey-manager
      seaweedfs
    ];
  };

  systemd.mounts = [
    {
      enable = true;
      what = "/dev/sda2";
      where = "/home/juuso/scratchpad";
      options = "subvolid=262";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;
      what = "/dev/sda2";
      where = "/var/lib/iwd";
      options = "subvolid=261";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;
      what = "/dev/sda2";
      where = "/home/juuso/.gnupg/trezor";
      options = "subvolid=259";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;
      what = "/dev/sda2";
      where = "/var/lib/fprint";
      options = "subvolid=270";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;
      what = "/dev/sda2";
      where = "/home/juuso/.papis";
      options = "subvolid=272";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;

      what = "/dev/sda2";
      where = "/home/juuso/.ssh";
      options = "subvolid=260";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;

      what = "/dev/sda2";
      where = "/home/juuso/.config/iamb";
      options = "subvolid=274";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;

      what = "/dev/sda2";
      where = "/home/juuso/.config/Yubico";
      options = "subvolid=275";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;

      what = "/dev/sda2";
      where = "/var/lib/ipfs";
      options = "subvolid=281";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;
      what = "/dev/sda2";
      where = "/var/lib/acme";
      options = "subvolid=282";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;
      what = "/dev/sda2";
      where = "/home/juuso/.local/share/sioyek";
      options = "subvolid=283";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;
      what = "/dev/sda2";
      where = "/home/juuso/.config/rclone";
      options = "subvolid=284";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
  ];

  hardware = {
    # enables WiFi and GPU drivers
    enableRedistributableFirmware = true;
    graphics = {
      enable = true; # radv: an open-source Vulkan driver from freedesktop
      extraPackages = [ pkgs.amdvlk ]; # amdvlk: an open-source driver from AMD
      # https://github.com/NixOS/nixpkgs/pull/320228
      # setLdLibraryPath = true;
    };

    ##
    ##  $ bluetoothctl
    ##  [bluetooth] # power on
    ##  [bluetooth] # agent on
    ##  [bluetooth] # default-agent
    ##  [bluetooth] # scan on
    ##  ...put device in pairing mode and wait [hex-address] to appear here...
    ##  [bluetooth] # pair [hex-address]
    ##  [bluetooth] # connect [hex-address]
    ## https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/LE-Audio-+-LC3-support
    bluetooth.enable = true;
  };

  services.fprintd.enable = true;

  services.dictd.enable = true;

  services.kubo = {
    enable = true;
    localDiscovery = true;
    settings = {
      Addresses.API = "/ip4/127.0.0.1/tcp/5001";
      API.HTTPHeaders = {
        Access-Control-Allow-Origin = [ "http://127.0.0.1:5001" "https://webui.ipfs.io" ];
        Access-Control-Allow-Methods = [ "PUT" "POST" ];
      };
      Ipns = {
        RepublishPeriod = "1h";
        RecordLifetime = "48h";
        ResolveCacheSize = 128;
        MaxCacheTTL = "1m";
      };
      Peering = {
        Peers = [
          {
            ID = "12D3KooWPpN7WoKZyBsYBVfwUDBtFaU22PJ5PgSaQRBx6gvn4Fg7";
            Addrs = [ "/ip4/192.168.76.40/tcp/4001" ];
          }
          {
            ID = "12D3KooWHfTqpJGCEDDetg9h75dx7b9X4cUdLbi9z1899wFrWYeh";
          }
        ];
      };
    };
  };

  services.netdata.enable = true;
  services.yubikey-agent.enable = true;
  services.trezord.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  services.dbus.enable = true;
  services.timesyncd.enable = true;
  services.timesyncd.servers = [ "time.cloudflare.com" ];

  # programs to enable also for root
  programs = {
    fish.enable = true;
    gamemode.enable = false;
    git.enable = true;
    gnupg.agent.pinentryPackage = pkgs.pinentry-curses;
    light.enable = true;
    steam.enable = false;
    sway.enable = true;
    vim.defaultEditor = true;
  };

  services.getty.autologinUser = "juuso";

  sops = with config.users.users; {
    age.sshKeyPaths = [ "${juuso.home}/.ssh/id_ed25519" ];
    defaultSopsFile = ./secrets/default.yaml;
    secrets."coredns/rewrites" = {
      owner = acme.name;
      inherit (acme) group;
      mode = "0440";
    };
    secrets."domain/cloudflare/juuso.dev" = { };
    secrets."ipfs/PrivKey" = { }; # cannot be used in derivation, but here for backup
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
    secrets."wireguard/ath0" = {
      owner = systemd-network.name;
      inherit (systemd-network) group;
    };
    secrets."wireguard/qmi0" = {
      owner = systemd-network.name;
      inherit (systemd-network) group;
    };
    secrets."wireguard/dinar" = {
      owner = systemd-network.name;
      inherit (systemd-network) group;
    };
    secrets."passage/trezor.age" = {
      owner = juuso.name;
      inherit (juuso) group;
    };
    secrets."passage/starlabs.age" = {
      owner = juuso.name;
      inherit (juuso) group;
    };
  };

  services.printing = {
    enable = false;
    clientConf = ''
      ServerName cups.cs.ox.ac.uk
    '';
  };
  services.avahi = {
    enable = false;
    nssmdns4 = true;
    openFirewall = true;
  };

  systemd.tmpfiles.rules = [
    "d /var/log/smartd 0755 netdata netdata -"
    "d /run/secrets/passage 0755 juuso juuso -"
  ];
  services.smartd = {
    enable = true;
    extraOptions = [
      "-A /var/log/smartd/"
      "--interval=600"
    ];
  };

  system.stateVersion = "24.05";

}
