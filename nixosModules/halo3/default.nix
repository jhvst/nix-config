{ lib
, pkgs
, ...
}:
{
  options = { };
  config = {

    boot = {
      kernelPackages = pkgs.linuxPackagesFor pkgs.linux;
    };

    environment.systemPackages = with pkgs; [
      btrfs-progs
      cifs-utils
      ntfs3g
      rsync
      yazi
      foot
    ];

    hardware = {
      amdgpu.initrd.enable = true;
      bluetooth.enable = true;
      enableRedistributableFirmware = true;
      graphics.enable = true;
      xpadneo.enable = true;
    };

    networking = {
      firewall.enable = false;
    };

    programs = {
      fish.enable = true;
      git.enable = true;
      vim = {
        enable = true;
        defaultEditor = true;
      };
    };

    security = {
      sudo = {
        enable = true;
        wheelNeedsPassword = lib.mkForce false;
      };
    };

    services = {
      avahi = {
        enable = true;
        nssmdns4 = true;
      };
      getty.autologinUser = "core";
      openssh.enable = true;
      speechd.enable = lib.mkForce false;
    };

    system.stateVersion = "25.05";

    time.timeZone = "Europe/Helsinki";

    users = {
      users.core = {
        isNormalUser = true;
        uid = 1000;
        group = "core";
        extraGroups = [ "wheel" "video" "input" ];
        password = "cortana";
        linger = true;
        shell = pkgs.fish;
      };
      groups.core.gid = 1000;
    };

  };
}
