{ config
, pkgs
, outputs
, ...
}:
{

  home-manager.users.juuso = _: {
    accounts.email.accounts = {
      "ponkila" = {
        astroid.enable = true;
        msmtp.enable = true;
        primary = true;
        mbsync = {
          enable = true;
          create = "maildir";
        };
        notmuch.enable = true;
        address = "juuso@ponkila.com";
        userName = "juuso@ponkila.com";
        realName = "Juuso Haavisto";
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
      "mail.com" = {
        astroid.enable = true;
        msmtp.enable = true;
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
      "gmail" = {
        msmtp.enable = true;
        astroid.enable = true;
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
          ''${pkgs.coreutils}/bin/cat ${config.sops.secrets."mbsync/gmail".path}''
        ];
        flavor = "gmail.com";
      };
      "oxford" = {
        astroid.enable = true;
        msmtp.enable = true;
        mbsync = {
          enable = true;
          create = "maildir";
          extraConfig.account = {
            CertificateFile = "/var/mnt/bakhal/davmail/davmail.crt";
          };
        };
        notmuch.enable = true;
        address = "juuso.haavisto@reuben.ox.ac.uk";
        userName = "reub0117@OX.AC.UK";
        realName = "Juuso Haavisto";
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
    programs = {
      astroid = {
        enable = true;
        extraConfig = {
          editor = {
            cmd = "${pkgs.foot}/bin/foot ${outputs.packages.x86_64-linux.neovim}/bin/nvim -c 'set ft=mail' '+set fileencoding=utf-8' '+set enc=utf-8' '+set ff=unix' '+set fo+=w' %1";
            external_editor = true;
          };
        };
        pollScript = "notmuch new";
      };
      mbsync.enable = true;
      msmtp.enable = true;
      notmuch.enable = true;
    };
    gtk = {
      enable = true;
      iconTheme = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
      };
    };
    services.mbsync.enable = true;

  };

}
