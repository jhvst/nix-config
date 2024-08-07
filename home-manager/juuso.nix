{ config
, lib
, ...
}:
{

  home-manager.users.juuso = { pkgs, ... }: {

    home.stateVersion = config.system.stateVersion;

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
              ''cat ${config.sops.secrets."mbsync/ponkila".path}''
            ];
            type = "caldav";
            url = "https://webmail.gandi.net/SOGo/dav/juuso@ponkila.com/Calendar/personal/";
            userName = "juuso@ponkila.com";
          };
          qcal.enable = true;
        };
        "mail.com" = {
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

    accounts.email.accounts = with config.home-manager.users.juuso; {
      "ponkila" = {
        primary = true;
        mbsync = {
          enable = true;
          create = "maildir";
        };
        neomutt.enable = true;
        notmuch.enable = true;
        address = "juuso@ponkila.com";
        userName = "juuso@ponkila.com";
        realName = "Juuso Haavisto";
        passwordCommand = [
          ''cat ${config.sops.secrets."mbsync/ponkila".path}''
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
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        neomutt.enable = true;
        notmuch.enable = true;
        address = "juuso@mail.com";
        userName = "juuso@mail.com";
        realName = "Juuso Haavisto";
        passwordCommand = [
          ''cat ${config.sops.secrets."mbsync/mail.com".path}''
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
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        neomutt.enable = true;
        notmuch.enable = true;
        address = "haavijuu@gmail.com";
        userName = "haavijuu@gmail.com";
        realName = "Juuso Haavisto";
        passwordCommand = [
          ''cat ${config.sops.secrets."mbsync/gmail".path}''
        ];
        flavor = "gmail.com";
      };
      "oxford" = {
        mbsync = {
          enable = true;
          create = "maildir";
          extraConfig.account = {
            CertificateFile = "${config.sops.secrets."davmail/oxford".path}";
          };
        };
        neomutt.enable = true;
        notmuch.enable = true;
        address = "juuso.haavisto@reuben.ox.ac.uk";
        userName = "reub0117@OX.AC.UK";
        realName = "Juuso Haavisto";
        passwordCommand = [
          ''cat ${config.sops.secrets."mbsync/oxford".path}''
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

    programs.alot.enable = true;
    programs.neomutt = {
      enable = true;
      sidebar.enable = true;
      vimKeys = true;
    };
    programs.notmuch = {
      enable = true;
    };
    programs.mbsync.enable = true;
    programs.qcal = {
      enable = true;
      timezone = config.time.timeZone;
    };

    programs.nix-index.enable = true;
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.fish = with config.home-manager.users.juuso; {
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
        push.autoSetupRemote = true;
        http = {
          # https://stackoverflow.com/questions/22369200/git-pull-push-error-rpc-failed-result-22-http-code-408
          postBuffer = "524288000";
        };
      };
    };
  };

}
