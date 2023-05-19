# nix-build -A pix.ipxe amd.nix -I home-manager=https://github.com/nix-community/home-manager/archive/master.tar.gz -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.zip

{ inputs, outputs, pkgs, config, lib, ... }:
{

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "iA-Writer" ]; })
  ];

  home-manager.users.juuso = {

    programs.foot = {
      enable = true;
      settings = {
        main = {
          term = "xterm-256color";

          font = "iMWritingMonoS Nerd Font:size=11";
          dpi-aware = "yes";
        };

        mouse = {
          hide-when-typing = "yes";
        };
      };
    };
    programs.firefox.enable = true;
    programs.waybar.enable = true;

    wayland.windowManager.sway = {
      enable = true;
      config = {
        bars = [{
          command = "${pkgs.waybar}/bin/waybar";
          fonts = {
            names = [ "iMWritingMonoS Nerd Font" ];
            style = "Bold Semi-Condensed";
            size = 11.0;
          };
        }];
        input = {
          "type:touchpad" = {
            tap = "disabled";
            natural_scroll = "enabled";
          };
        };
      };
    };
  };

  networking.hostName = "starlabs";
  time.timeZone = "Europe/London";

  boot.kernelParams = [
    "boot.shell_on_fail"
  ];
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  users.users.juuso = {
    isNormalUser = true;
    group = "juuso";
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMKgTTpGSvPG4p8pRUWg1kqnP9zPKybTHQ0+Q/noY5+M6uOxkLy7FqUIEFUT9ZS/fflLlC/AlJsFBU212UzobA= ssh@secretive.sandbox.local"
    ];
  };
  users.groups.juuso = { };

  security.sudo = {
    enable = lib.mkDefault true;
    wheelNeedsPassword = lib.mkForce false;
  };
  networking.wireless.iwd.enable = true;

  environment.systemPackages = with pkgs; [
    btrfs-progs
    lm_sensors
    nfs-utils
  ];

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
      where = "/home/juuso/.ssh";
      options = "subvolid=260";
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
  ];

  hardware.opengl = {
    ## radv: an open-source Vulkan driver from freedesktop
    driSupport = true;
    driSupport32Bit = true;
  };

  hardware.xpadneo.enable = true;

  ##
  ##  $ bluetoothctl
  ##  [bluetooth] # power on
  ##  [bluetooth] # agent on
  ##  [bluetooth] # default-agent
  ##  [bluetooth] # scan on
  ##  ...put device in pairing mode and wait [hex-address] to appear here...
  ##  [bluetooth] # pair [hex-address]
  ##  [bluetooth] # connect [hex-address]
  hardware.bluetooth.enable = true;

  # "my laptop has LVFS updates btw"
  services.fwupd.enable = true;

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

  security.rtkit.enable = true;

  ## Window manager
  programs.sway.enable = true;
  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';
  services.getty.autologinUser = "juuso";

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  system.stateVersion = "23.05";
}
