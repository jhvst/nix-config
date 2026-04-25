{ pkgs, ... }: {

  boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1; # Ubisoft Connect fix: https://www.protondb.com/app/2225070#5tJ0kpnj43

  home-manager.users.juuso = {
    home.packages = with pkgs; [
      discord
      mangohud
    ];
    wayland.windowManager.sway = {
      enable = true;
      config = {
        terminal = "foot";
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
  };

  programs = {
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        distroav
        wlrobs
      ];
    };
    steam = {
      enable = true;
      gamescopeSession = {
        enable = true;
        args = [
          "--hdr-enabled"
          "--mangoapp"
          "--rt"
          "--steam"
        ];
        env = {
          MANGOHUD = "1";
          MANGOHUD_CONFIG = "full";
        };
      };
      localNetworkGameTransfers.openFirewall = true;
    };
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    gamemode.enable = true;
  };

  # avahi is required by distroav
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

}
