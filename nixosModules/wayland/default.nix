{ config
, pkgs
, lib
, ...
}:
{
  options = { };
  config = {
    fonts = {
      fontDir.enable = true;
      packages = with pkgs; [
        (nerdfonts.override { fonts = [ "IBMPlexMono" ]; })
        departure-mono
      ];
    };

    home-manager.users.juuso = {
      programs.foot = {
        enable = true;
        settings = {
          main = {
            term = "xterm-256color";
            font = "BlexMono Nerd Font Mono:size=11";
          };
          mouse = {
            hide-when-typing = "yes";
          };
          url = {
            launch = "${pkgs.nix} run nixpkgs#firefox -- ";
          };
        };
      };
      programs.yambar = {
        enable = true;
        settings.bar = {
          font = "Departure Mono:style=Regular";
          location = "top";
          height = 26;
          background = "00000066";
        };
        settings.bar.left = [{
          i3 = rec {
            right-spacing = 6;
            persistent = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
            content =
              let
                workspace = n: {
                  name = n;
                  value = let s = { text = if n == "10" then "0" else n; margin = 8; }; in {
                    map = {
                      default.string = s;
                      conditions = {
                        empty.string = s // {
                          foreground = "ffffff77";
                        };
                        focused.string = s // {
                          deco.underline = {
                            size = 2;
                            color = "ffffffff";
                          };
                        };
                        urgent.string = s // {
                          deco.background.color = "dd5555ff";
                        };
                      };
                    };
                  };
                };
              in
              builtins.listToAttrs (map workspace persistent);
          };
        }];
        settings.bar.center = [
          {
            label = {
              content = [{
                string.text = config.networking.hostName;
              }];
            };
          }
        ];
      };
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

    hardware = {
      enableRedistributableFirmware = true;
      graphics.enable = true;
      bluetooth.enable = lib.mkDefault true;
    };

    documentation = {
      # html docs and info are not required, man pages are enough
      doc.enable = false;
      info.enable = false;
    };

    # https://github.com/NixOS/nixpkgs/pull/330440#issuecomment-2369082964
    services.speechd.enable = lib.mkForce false;

    programs = {
      sway = {
        enable = true;
        extraPackages = with pkgs; [
          foot
          light
          swaylock
          wl-clipboard
          wlsunset
          wmenu
        ];
      };
    };
  };
}
