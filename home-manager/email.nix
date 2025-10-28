{ config
, ...
}:
{

  home-manager.users.juuso = _: {
    accounts.email.accounts = {
      "ponkila" = {
        thunderbird.enable = true;
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
          ''cat ${config.sops.secrets."mbsync/ponkila".path}''
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
        thunderbird.enable = true;
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
        thunderbird.enable = true;
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
          ''cat ${config.sops.secrets."mbsync/gmail".path}''
        ];
        flavor = "gmail.com";
      };
      "oxford" = {
        thunderbird.enable = true;
        mbsync = {
          enable = true;
          create = "maildir";
          extraConfig.account = {
            CertificateFile = "${config.sops.secrets."davmail/oxford".path}";
          };
        };
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

    programs.notmuch = {
      enable = true;
    };
    programs.mbsync.enable = true;
    programs.thunderbird = {
      enable = true;
      profiles = {
        ponkila.isDefault = true;
      };
    };

  };

}
