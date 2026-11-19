{ pkgs, ... }: {

  boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1; # Ubisoft Connect fix: https://www.protondb.com/app/2225070#5tJ0kpnj43

  home-manager.users.juuso = {
    home.packages = with pkgs; [
      discord
      faugus-launcher
      mangohud
    ];
    # required for 4:3 gaming
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
    gamemode = {
      enable = true;
      settings = {
        general = {
          renice = 10;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          amd_performance_level = "high";
        };
      };
    };
  };

}
