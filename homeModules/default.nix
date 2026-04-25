{ config
, inputs
, lib
, ...
}:
let
  cfg = config.homeModule;
  mkMailAccount = name: extra: lib.recursiveUpdate
    {
      address = name;
      msmtp.enable = true;
      notmuch.enable = true;
      realName = "Juuso Haavisto";
    }
    extra;
in
{
  options = {
    homeModule.email = lib.mkEnableOption "email sync";
  };
  config = {
    home-manager = {
      backupFileExtension = "backup";
      sharedModules = [ inputs.nixvim.homeManagerModules.nixvim ];
      useGlobalPkgs = true;
      users.juuso = { pkgs, ... }: with config.home-manager.users.juuso; {
        accounts = {
          calendar = {
            accounts = {
              "ponkila" = {
                primary = true;
                primaryCollection = "Personal Calendar";
                local = {
                  type = "filesystem";
                  fileExt = ".ics";
                };
                remote = {
                  passwordCommand = [
                    ''cat ${config.sops.secrets."mbsync/ponkila".path}''
                  ];
                  type = "caldav";
                  url = "https://webmail.gandi.net/SOGo/dav/juuso@ponkila.com/Calendar/personal/";
                  userName = "juuso@ponkila.com";
                };
                qcal.enable = true;
              };
              "mail" = {
                primary = false;
                primaryCollection = "My Calendar";
                local = {
                  type = "filesystem";
                  fileExt = ".ics";
                };
                remote = {
                  passwordCommand = [
                    ''cat ${config.sops.secrets."mbsync/mail.com".path}''
                  ];
                  type = "caldav";
                  url = "https://caldav.mail.com/begenda/dav/juuso@mail.com/calendar/";
                  userName = "juuso@mail.com";
                };
                qcal.enable = true;
              };
              "oxford" = {
                primary = false;
                primaryCollection = "Calendar";
                local = {
                  type = "filesystem";
                  fileExt = ".ics";
                };
                remote = {
                  passwordCommand = [
                    ''cat ${config.sops.secrets."mbsync/oxford".path}''
                  ];
                  type = "caldav";
                  url = "http://192.168.76.40:1080/users/reub0117@OX.AC.UK/calendar";
                  userName = "reub0117@OX.AC.UK";
                };
                qcal.enable = true;
              };
            };
            basePath = ".calendar";
          };
          email.accounts = lib.mkIf cfg.email {
            "ponkila" = mkMailAccount "juuso@ponkila.com" {
              primary = true;
              mbsync = {
                enable = true;
                create = "maildir";
              };
              userName = "juuso@ponkila.com";
              passwordCommand = [
                ''${pkgs.coreutils}/bin/cat ${config.sops.secrets."mbsync/ponkila".path}''
              ];
              imap = {
                host = "mail.your-server.de";
                port = 143;
                tls = {
                  enable = true;
                  useStartTls = true;
                };
              };
              smtp = {
                host = "mail.your-server.de";
                port = 587;
                tls = {
                  enable = true;
                  useStartTls = true;
                };
              };
            };
            "mail" = mkMailAccount "juuso@mail.com" {
              mbsync = {
                enable = true;
                create = "both";
              };
              userName = "juuso@mail.com";
              passwordCommand = [
                ''${pkgs.coreutils}/bin/cat ${config.sops.secrets."mbsync/mail.com".path}''
              ];
              imap = {
                host = "imap.mail.com";
                port = 993;
                tls = {
                  enable = true;
                };
              };
              smtp = {
                host = "smtp.mail.com";
                port = 587;
                tls = {
                  useStartTls = true;
                };
              };
            };
            "gmail" = mkMailAccount "haavijuu@gmail.com" {
              mbsync = {
                enable = true;
                create = "both";
              };
              userName = "haavijuu@gmail.com";
              passwordCommand = [
                ''${pkgs.coreutils}/bin/cat ${config.sops.secrets."mbsync/gmail".path}''
              ];
              flavor = "gmail.com";
            };
            "oxford" = mkMailAccount "juuso.haavisto@reuben.ox.ac.uk" {
              mbsync = {
                enable = true;
                create = "maildir";
                extraConfig.account = {
                  CertificateFile = "/var/mnt/bakhal/davmail/davmail.crt";
                };
              };
              aliases = [ "juuso.haavisto@cs.ox.ac.uk" ];
              userName = "reub0117@OX.AC.UK";
              passwordCommand = [
                ''${pkgs.coreutils}/bin/cat ${config.sops.secrets."mbsync/oxford".path}''
              ];
              imap = {
                host = "192.168.76.40";
                port = 1143;
                tls = {
                  enable = true;
                };
              };
              smtp = {
                host = "192.168.76.40";
                port = 1025;
                tls = {
                  enable = true;
                };
              };
            };
          };
        };
        editorconfig = {
          enable = true;
          settings."*" = {
            charset = "utf-8";
            end_of_line = "lf";
            indent_size = 2;
            indent_style = "space";
            insert_final_newline = true;
            max_line_width = 78;
            trim_trailing_whitespace = true;
          };
        };
        home.stateVersion = config.system.stateVersion;
        programs = {
          alot.enable = cfg.email;
          awscli = {
            enable = true;
            # https://l-lin.github.io/devops/cloud/aws/AWS-CLI-with-Unix-password-manager
            credentials = {
              "default" = {
                "credential_process" = "${pkgs.passage}/bin/passage show garage/nix";
              };
            };
            settings = {
              "default" = {
                region = "garage";
                endpoint_url = "http://nix-cache.s3.muro.ponkila.nix:3900";
              };
            };
          };
          direnv = {
            enable = true;
            nix-direnv.enable = true;
          };
          fish = {
            enable = true;
            loginShellInit = ''
              set -U fish_greeting
              set -x IPFS_PATH ${config.services.kubo.dataDir}
              set -x PATH '${lib.concatStringsSep ":" [
                "${home.homeDirectory}/.nix-profile/bin"
                "/run/wrappers/bin"
                "/etc/profiles/per-user/${home.username}/bin"
                "/run/current-system/sw/bin"
                "/nix/var/nix/profiles/default/bin"
              ]}'
              test $TERM = "xterm-256color"; and exec tmux
            '';
          };
          foot = {
            enable = true;
            settings = {
              main = {
                term = "xterm-256color";
                font = "IosevkaTerm Nerd Font Mono:size=12";
              };
              mouse = {
                hide-when-typing = "yes";
              };
              url = {
                launch = "${pkgs.nix} run nixpkgs#firefox -- ";
              };
            };
          };
          fzf.enable = true; # https://andrew-quinn.me/fzf/
          git = {
            enable = true;
            ignores = [
              ".DS_Store"
              ".direnv"
              "node_modules"
              "result"
              ".devenv"
            ];
          };
          gpg = {
            enable = true;
            homedir = "${home.homeDirectory}/.gnupg/trezor";
            settings = {
              agent-program = "${pkgs.trezor-agent}/bin/trezor-gpg-agent";
              default-key = "Juuso Haavisto <juuso@ponkila.com>";
            };
          };
          mbsync.enable = cfg.email;
          mergiraf.enable = true;
          msmtp.enable = cfg.email;
          nixvim =
            let
              neovim = (import ../nixosModules/neovim) {
                inherit config pkgs;
              };
            in
            with neovim.config; {
              inherit
                colorschemes
                extraConfigLua
                extraConfigVim
                extraPackages
                extraPlugins
                plugins;
              enable = true;
              defaultEditor = true;
              viAlias = true;
              vimAlias = true;
            };
          notmuch.enable = cfg.email;
          papis = {
            enable = true;
            libraries."papers" = {
              isDefault = true;
              settings = {
                dir = "/var/lib/papis";
              };
            };
            settings = {
              add-edit = true;
            };
          };
          password-store = {
            enable = true;
            package = pkgs.passage;
            settings = {
              PASSAGE_DIR = "/var/lib/passage";
              PASSAGE_IDENTITIES_FILE = "/run/secrets/passage";
              PASSAGE_RECIPIENTS = "age1ef70t0zmlcvpe4ppwfdza7qpv2uakq9c9ldrv0y9zfnvdka7acnsxkkmzl age12lz3jyd2weej5c4mgmwlwsl0zmk2tdgvtflctgryx6gjcaf3yfsqgt7rnz age1mlhf96qy5ftr52jvf6lh2mwzm6gpxk95dnra2djkyfy2ug4yyamqdnnfl2";
              PASSWORD_STORE_CLIP_TIME = "60";
            };
          };
          qcal = {
            enable = true;
            timezone = config.time.timeZone;
          };
          sioyek.enable = true;
          ssh = {
            enable = true;
            enableDefaultConfig = false;
            matchBlocks."*" = {
              hashKnownHosts = true;
              identityFile = "~/.ssh/id_ed25519_sk_rk";
            };
          };
          tmux = {
            enable = true;
            baseIndex = 1;
            plugins = with pkgs.tmuxPlugins; [
              extrakto # Ctrl+Space+Tab
              tilish # Option+Enter
              tmux-fzf # Ctrl+Space+f
            ];
            extraConfig = ''
              set -g @tilish-dmenu 'on'
              set -g mouse on

              bind | split-window -h
              unbind %

              set -g focus-events on
              set-option -g default-shell "${pkgs.fish}/bin/fish"

              set-option -sg escape-time 10
              set-option -g default-terminal "tmux-256color"
              set-option -sa terminal-features ",*:RGB"

              TMUX_FZF_LAUNCH_KEY="f"
            '';
            shortcut = "Space";
          };
          yambar = {
            enable = true;
            settings.bar = {
              font = "IosevkaTerm Nerd Font:style=Regular";
              location = "top";
              height = 26;
              background = "00000066";
              center = [{
                label.content = [{
                  string.text = config.networking.hostName;
                }];
              }];
              right = [
                {
                  mem = {
                    poll-interval = 2500;
                    content = [{
                      string.text = " {free:mb}MB";
                    }];
                  };
                }
                {
                  clock = {
                    time-format = "%H:%M:%S";
                    date-format = "%A %-d of %b %Y %z";
                    content = [
                      {
                        string.text = " {date}";
                      }
                      {
                        string.text = "{time}";
                      }
                    ];
                  };
                }
              ];
            };
          };
        };
        services = {
          mako.enable = true;
          mbsync = {
            enable = cfg.email;
            frequency = "*:0/15";
          };
        };
      };
    };
  };
}
