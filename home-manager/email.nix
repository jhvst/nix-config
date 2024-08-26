{ config
, lib
, ...
}:
{

  home-manager.users.juuso = { pkgs, ... }: {
    
    accounts.email.accounts = with config.home-manager.users.juuso; {
      "ponkila" = {
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
    programs.notmuch = {
      enable = true;
    };
    programs.mbsync.enable = true;
   
}
