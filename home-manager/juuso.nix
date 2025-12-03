{ config
, lib
, ...
}:
{

  home-manager.backupFileExtension = "backup";
  home-manager.users.juuso = { pkgs, ... }: with config.home-manager.users.juuso; {

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

    programs = {
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
      qcal = {
        enable = true;
        timezone = config.time.timeZone;
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
    };
  };

}
