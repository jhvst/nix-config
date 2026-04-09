{ config
, pkgs
, lib
, ...
}:
let
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
  home-manager.users.juuso = _: {
    accounts.email.accounts = {
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
    programs = {
      alot.enable = true;
      mbsync.enable = true;
      msmtp.enable = true;
      notmuch.enable = true;
    };
    services.mbsync = {
      enable = true;
      frequency = "*:0/15";
    };
  };
}
