_: {

  home-manager.users.juuso.programs.sioyek = {
    enable = true;
    config = {
      should_highlight_links = "1";
      link_highlight_color = "1.0 0.0 0.0";
    };
  };
  services.dictd.enable = true;

}
