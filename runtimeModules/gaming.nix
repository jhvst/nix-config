{ pkgs, ... }: {

  boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1; # Ubisoft Connect fix: https://www.protondb.com/app/2225070#5tJ0kpnj43

  programs = {
    obs-studio = { enable = true; plugins = [ pkgs.obs-studio-plugins.wlrobs ]; };
    steam.enable = true;
    gamescope.enable = true;
    gamemode.enable = true;
  };

  environment.systemPackages = with pkgs; [
    discord
  ];

}
