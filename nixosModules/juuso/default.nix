{ config
, pkgs
, ...
}:
{
  options = { };
  config = {
    boot = {
      kernelModules = [
        "v4l2loopback"
      ];
      extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
      extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      '';
    };
    environment = {
      shells = [ pkgs.fish ];
      systemPackages = with pkgs; [
        age-plugin-fido2-hmac
        binwalk
        btrfs-progs
        cifs-utils
        cryptsetup
        file
        gnupg
        isd
        nix-output-monitor
        pinentry-curses
        sioyek
        sops
        trezor-agent
        trezorctl
        wireguard-tools
        wl-clipboard
        wlsunset
        xdg-utils # open command
        xfsprogs
        xorg.xkbcomp
        xwayland-satellite
        yazi
        yubikey-manager
      ];
    };
    programs.git = {
      enable = true;
      lfs.enable = true;
      config = {
        branch.sort = "-committerdate";
        column.ui = "auto";
        commit.gpgsign = true;
        commit.verbose = true;
        diff.algorithm = "histogram";
        diff.colorMoved = "plain";
        diff.mnemonicPrefix = true;
        diff.renames = true;
        fetch.all = true;
        fetch.prune = true;
        fetch.pruneTags = true;
        gpg.format = "ssh";
        gpg.ssh.program = "${pkgs.openssh}/bin/ssh-keygen";
        http.postbuffer = 524288000; # https://stackoverflow.com/questions/22369200/git-pull-push-error-rpc-failed-result-22-http-code-408
        init.defaultBranch = "main";
        merge.conflictstyle = "zdiff3";
        pull.rebase = true;
        push.autosetupremote = true;
        push.default = "simple";
        push.followTags = true;
        rebase.autoSquash = true;
        rebase.autoStash = true;
        rebase.updateRefs = true;
        tag.gpgsign = true;
        tag.sort = "version:refname";
        user.email = "juuso@ponkila.com";
        user.name = "Juuso Haavisto";
        user.signingkey = "/home/juuso/.ssh/id_ed25519_sk_rk_starlabs";
      };
    };
    services = {
      trezord.enable = true;
      yubikey-agent.enable = true;
    };
  };
}
