{ pkgs, ... }: {

  boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1; # Ubisoft Connect fix: https://www.protondb.com/app/2225070#5tJ0kpnj43

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
    };
    gamescope.enable = true;
    gamemode.enable = true;
  };

  environment.systemPackages = with pkgs; [
    discord
    mangohud
  ];

  # avahi is required by distroav
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

}
