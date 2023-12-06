{ inputs
, config
, pkgs
, lib
, ...
}:
{

  home-manager.users.juuso = { pkgs, ... }: {

    home.stateVersion = "23.11";

    accounts.calendar = {
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
              ''cat $(getconf DARWIN_USER_TEMP_DIR)email/ponkila.com''
            ];
            type = "caldav";
            url = "https://webmail.gandi.net/SOGo/dav/juuso@ponkila.com/Calendar/personal/";
            userName = "juuso@ponkila.com";
          };
          qcal.enable = true;
        };
      };
      accounts = {
        "mail.com" = {
          primary = false;
          primaryCollection = "My Calendar";
          local = {
            type = "filesystem";
            fileExt = ".ics";
          };
          remote = {
            passwordCommand = [
              ''cat $(getconf DARWIN_USER_TEMP_DIR)email/mail.com''
            ];
            type = "caldav";
            url = "https://caldav.mail.com/begenda/dav/juuso@mail.com/calendar/";
            userName = "juuso@mail.com";
          };
          qcal.enable = true;
        };
      };
      basePath = ".calendar";
    };

    accounts.email.accounts = with config.home-manager.users.juuso; {
      "ponkila" = {
        primary = true;
        himalaya = {
          enable = true;
          settings = {
            backend = "notmuch";
            notmuch-db-path = "${home.homeDirectory}/Maildir";
            sender = "smtp";

            folder-aliases = {
              inbox = "tag:inbox";
            };
          };
        };
        mbsync = {
          enable = true;
          create = "maildir";
        };
        notmuch.enable = true;
        address = "juuso@ponkila.com";
        userName = "juuso@ponkila.com";
        realName = "Juuso Haavisto";
        passwordCommand = [
          ''cat $(getconf DARWIN_USER_TEMP_DIR)email/ponkila.com''
        ];
        imap = {
          host = "mail.gandi.net";
          port = 993;
          tls = {
            enable = true;
          };
        };
        smtp = {
          host = "mail.gandi.net";
          port = 465;
          tls = {
            enable = true;
          };
        };
      };
      "mail.com" = {
        himalaya = {
          enable = true;
          settings = {
            backend = "notmuch";
            notmuch-db-path = "${home.homeDirectory}/Maildir";
            sender = "smtp";

            folder-aliases = {
              inbox = "tag:inbox";
            };
          };
        };
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        notmuch.enable = true;
        address = "juuso@mail.com";
        userName = "juuso@mail.com";
        realName = "Juuso Haavisto";
        passwordCommand = [
          ''cat $(getconf DARWIN_USER_TEMP_DIR)email/mail.com''
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
      "gmail" = {
        himalaya = {
          enable = true;
          settings = {
            backend = "notmuch";
            notmuch-db-path = "${home.homeDirectory}/Maildir";
            sender = "smtp";

            folder-aliases = {
              inbox = "tag:inbox";
            };
          };
        };
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        notmuch.enable = true;
        address = "haavijuu@gmail.com";
        userName = "haavijuu@gmail.com";
        realName = "Juuso Haavisto";
        passwordCommand = [
          ''security find-generic-password -a haavijuu@gmail.com -w''
        ];
        flavor = "gmail.com";
      };
      "oxford" = {
        himalaya = {
          enable = true;
          settings = {
            backend = "notmuch";
            notmuch-db-path = "${home.homeDirectory}/Maildir";
            sender = "smtp";

            folder-aliases = {
              inbox = "tag:inbox";
            };
          };
        };
        mbsync = {
          enable = true;
          create = "maildir";
          extraConfig.account = {
            CertificateFile = "~/.config/davmail/oxford/davmail.pem";
          };
        };
        notmuch.enable = true;
        address = "juuso.haavisto@reuben.ox.ac.uk";
        userName = "reub0117@OX.AC.UK";
        realName = "Juuso Haavisto";
        passwordCommand = [
          ''security find-generic-password -a reub0117@OX.AC.UK -w''
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

    programs.notmuch = {
      enable = true;
      hooks = {
        preNew = "mbsync --all";
      };
    };
    programs.mbsync.enable = true;
    programs.himalaya = {
      enable = true;
      package = pkgs.himalaya.override { withNotmuchBackend = true; };
    };
    programs.qcal.enable = true;

    programs.nix-index.enable = true;
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.htop.enable = true;

    home.packages = with pkgs; [
      gnupg
      trezor_agent
      trezord
      wireguard-go
      wireguard-tools
    ];

    programs.fish = with config.home-manager.users.juuso; {
      enable = true;
      loginShellInit = ''
        ${if pkgs.system == "aarch64-darwin" then
          "set -x ponkila (getconf DARWIN_USER_TEMP_DIR)${sops.secrets."wireguard/ponkila.conf".name}"
        else ""}
        set -U fish_greeting
        set -x GNUPGHOME ${home.homeDirectory}/.gnupg/trezor
        set -x PATH '${lib.concatStringsSep ":" [
          "${home.homeDirectory}/.nix-profile/bin"
          "/run/wrappers/bin"
          "/etc/profiles/per-user/${home.username}/bin"
          "/run/current-system/sw/bin"
          "/nix/var/nix/profiles/default/bin"
          "/opt/homebrew/bin"
          "/usr/bin"
          "/sbin"
          "/bin"
        ]}'
        test $TERM = "xterm-256color"; and exec tmux
      '';
    };

    programs.tmux = {
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

    # https://andrew-quinn.me/fzf/
    programs.fzf.enable = true;

    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      signing.key = "8F84B8738E67A3453F05D29BC2DC6A67CB7F891F";
      signing.signByDefault = true;
      userEmail = "juuso@ponkila.com";
      userName = "Juuso Haavisto";
      ignores = [
        ".DS_Store"
        ".direnv"
        "node_modules"
        "result"
        ".devenv"
      ];
      extraConfig = {
        http = {
          # https://stackoverflow.com/questions/22369200/git-pull-push-error-rpc-failed-result-22-http-code-408
          postBuffer = "524288000";
        };
      };
    };
  };

}
