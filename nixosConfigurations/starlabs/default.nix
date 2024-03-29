{ inputs, outputs, pkgs, config, lib, ... }:
{

  # early console
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.initrd.luks.fido2Support = true;

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

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "IBMPlexMono" ]; })
  ];

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

    programs.browserpass = {
      enable = true;
      browsers = [ "firefox" ];
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

  boot.kernelParams = [
    "boot.shell_on_fail"
  ];
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  users.users.juuso = {
    isNormalUser = true;
    group = "juuso";
    extraGroups = [ "wheel" "networkmanager" "video" "input" "pipewire" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMKgTTpGSvPG4p8pRUWg1kqnP9zPKybTHQ0+Q/noY5+M6uOxkLy7FqUIEFUT9ZS/fflLlC/AlJsFBU212UzobA= ssh@secretive.sandbox.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDq7kUCTPNw8SPNbGsNslECroKNljRGZk9fIBIEzrvI epsilon"
    ];
    shell = pkgs.fish;
  };
  users.groups.juuso = { };
  #programs.steam.enable = true;

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
      nfs-utils
      nix-output-monitor
      nix-update
      passage
      pinentry
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
      what = "muro.ponkila.periferia:/nfs";
      where = "/var/mnt/muro";
      mountConfig = {
        Options = "noatime,nfsvers=4.2";
      };
      type = "nfs";
    }
    {
      enable = true;
      what = "muro.ponkila.periferia:/Maildir";
      where = "/home/juuso/Maildir";
      mountConfig = {
        Options = "noatime,nfsvers=4.2";
      };
      type = "nfs";
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
  ];

  systemd.automounts = [
    {
      where = "/var/mnt/muro";
      automountConfig = {
        TimeoutIdleSec = "600";
      };

      after = [ "wg-quick-ponkila.service" ];
      wantedBy = [ "multi-user.target" ];
    }
    {
      where = "/home/juuso/Maildir";
      automountConfig = {
        TimeoutIdleSec = "600";
      };

      after = [ "wg-quick-ponkila.service" ];
      before = [ "home-manager-juuso.service" ];
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

  services.udev = {
    packages = [ pkgs.yubikey-personalization ];
    extraRules = ''
      ACTION=="remove",\
      ENV{ID_BUS}=="usb",\
      ENV{ID_MODEL_ID}=="0407",\
      ENV{ID_VENDOR_ID}=="1050",\
      ENV{ID_VENDOR}=="Yubico",\
      RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    '';
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

  # NFS mounting support
  services.rpcbind.enable = true;

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
    gnupg.agent.pinentryFlavor = "curses";
    sway.enable = true;
    vim.defaultEditor = true;
  };

  # usbmuxd makes the iPhone pairable via USB cable
  services.usbmuxd.enable = true;

  services.getty.autologinUser = "juuso";

  sops = with config.users.users; {
    defaultSopsFile = ./secrets/default.yaml;
    secrets."mbsync/ponkila" = {
      owner = juuso.name;
      group = juuso.group;
    };
    secrets."mbsync/mail.com" = {
      owner = juuso.name;
      group = juuso.group;
    };
    secrets."mbsync/gmail" = {
      owner = juuso.name;
      group = juuso.group;
    };
    secrets."mbsync/oxford" = {
      owner = juuso.name;
      group = juuso.group;
    };
    secrets."davmail/oxford" = {
      owner = juuso.name;
      group = juuso.group;
    };
    secrets."nix-serve" = { };
  };

  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    secretKeyFile = config.sops.secrets."nix-serve".path;
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

  networking.firewall.interfaces."ponkila" = {
    allowedTCPPorts = [ 5000 ];
  };

  system.stateVersion = "24.05";

}
