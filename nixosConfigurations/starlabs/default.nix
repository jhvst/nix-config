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
          dpi-aware = "yes";
        };
        mouse = {
          hide-when-typing = "yes";
        };
      };
    };

    programs.waybar.enable = true;
    programs.swaylock.enable = true;

    wayland.windowManager.sway = {
      enable = true;
      config = {
        terminal = "foot";
        bars = [{
          command = "${pkgs.waybar}/bin/waybar";
          fonts = {
            names = [ "BlexMono Nerd Font Mono" ];
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

    programs.password-store = with config.home-manager.users.juuso; {
      enable = true;
      settings = {
        PASSWORD_STORE_DIR = "${home.homeDirectory}/.pass";
        PASSWORD_STORE_KEY = "8F84B8738E67A3453F05D29BC2DC6A67CB7F891F";
      };
    };

  };

  networking = {
    hostName = "starlabs";
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
      "192.168.17.1"
      "2001:470:27:6a9:8000::1"
    ];
    useDHCP = true;
    wireless.iwd.enable = true;
    stevenblack.enable = true;

    wg-quick.interfaces = {
      "ponkila".configFile = "/etc/wireguard/ponkila.conf";
      "dinar".configFile = "/etc/wireguard/dinar.conf";
      "rut0".configFile = "/etc/wireguard/rut0.conf";
    };
  };

  time.timeZone = "Europe/London";

  users = {
    mutableUsers = false;
    users.juuso = {
      isNormalUser = true;
      uid = 1000;
      group = "juuso";
      extraGroups = [ "wheel" "networkmanager" "video" "input" "pipewire" "ipfs" ];
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
      btrfs-progs
      cryptsetup
      gnupg
      iamb # matrix client
      nix-output-monitor
      nix-update
      passage
      pinentry
      sioyek
      sops
      wl-clipboard
      xdg-utils # open command
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
      where = "/etc/wireguard";
      options = "subvolid=263";
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
      where = "/home/juuso/.pass";
      options = "subvolid=271";
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
      where = "/home/juuso/.passage";
      options = "subvolid=279";
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
  ];

  hardware = {
    # enables WiFi and GPU drivers
    enableRedistributableFirmware = true;
    opengl = {
      # radv: an open-source Vulkan driver from freedesktop
      driSupport = true;
      driSupport32Bit = true;

      setLdLibraryPath = true;

      # amdvlk: an open-source driver from AMD
      # for some reason integrated GPUs are not detected without amdvlk, and it is seemingly impossible to disable radv
      extraPackages = [
        pkgs.amdvlk
      ];
      extraPackages32 = [
        pkgs.driversi686Linux.amdvlk
      ];
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
    # Xbox controller
    xpadneo.enable = true;
  };

  services.fprintd.enable = true;

  services.kubo = {
    enable = true;
    localDiscovery = true;
    settings = {
      Addresses.API = "/ip4/127.0.0.1/tcp/5001";
      API.HTTPHeaders = {
        Access-Control-Allow-Origin = [ "http://127.0.0.1:5001" "https://webui.ipfs.io" ];
        Access-Control-Allow-Methods = [ "PUT" "POST" ];
      };
      Peering = {
        Peers = [{
          ID = "12D3KooWPpN7WoKZyBsYBVfwUDBtFaU22PJ5PgSaQRBx6gvn4Fg7";
          Addrs = [ "/ip4/192.168.76.40/tcp/4001" ];
        }];
      };
    };
  };

  services.yubikey-agent.enable = true;
  services.trezord.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  ### System APIs
  services.dbus.enable = true;

  services.timesyncd.enable = false;
  services.chrony = {
    enable = true;
    servers = [
      "ntp1.hetzner.de"
      "ntp2.hetzner.com"
      "ntp3.hetzner.net"
    ];
  };

  services.openssh = {
    enable = true;
    hostKeys = [{
      path = "/home/juuso/.ssh/id_ed25519";
      type = "ed25519";
    }];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # programs to enable also for root
  programs = {
    fish.enable = true;
    git.enable = true;
    gnupg.agent.pinentryPackage = pkgs.pinentry-curses;
    sway.enable = true;
    vim.defaultEditor = true;
    steam.enable = false;
  };

  # usbmuxd makes the iPhone pairable via USB cable
  services.usbmuxd.enable = true;

  services.getty.autologinUser = "juuso";

  sops = with config.users.users; {
    defaultSopsFile = ./secrets/default.yaml;
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
    secrets."nix-serve" = { };
  };

  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    secretKeyFile = config.sops.secrets."nix-serve".path;
  };
  networking.firewall.interfaces."ponkila" = {
    allowedTCPPorts = [ 5000 ];
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

  system.stateVersion = "24.05";

}
