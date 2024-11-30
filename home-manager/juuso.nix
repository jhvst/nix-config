{ config
, lib
, ...
}:
{

  home-manager.backupFileExtension = "backup";
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

    programs.qcal = {
      enable = true;
      timezone = config.time.timeZone;
    };

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
      signing = with config.home-manager.users.juuso; {
        format = "ssh";
        key = "${home.homeDirectory}/.ssh/id_ed25519_sk_rk_starlabs";
        signByDefault = true;
      };
      lfs.enable = true;
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
