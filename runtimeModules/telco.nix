{ pkgs, ... }: {
  programs = {
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        distroav
        wlrobs
      ];
    };
  };
  # avahi is required by distroav
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
