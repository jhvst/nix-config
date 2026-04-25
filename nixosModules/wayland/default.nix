{ pkgs
, ...
}:
{
  options = { };
  config = {
    fonts = {
      fontDir.enable = true;
      packages = with pkgs; [
        nerd-fonts.iosevka-term
      ];
    };

    home-manager.users.juuso = {
      programs.swaylock.enable = true;

      wayland.windowManager.sway = {
        enable = true;
        config = {
          terminal = "foot";
          bars = [{
            command = "${pkgs.yambar}/bin/yambar";
            fonts = {
              names = [ "Departure Mono" ];
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
    };

    programs = {
      sway = {
        enable = true;
        extraPackages = with pkgs; [
          foot
          swaylock
          wl-clipboard
          wlsunset
          wmenu
        ];
      };
    };
  };
}
