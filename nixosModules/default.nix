{ config
, pkgs
, lib
, ...
}:
{
  options = { };
  config = {
    boot = {
      kernelModules = [ "v4l2loopback" ];
      extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
      extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      '';
    };
    documentation = {
      # man pages shall suffice
      doc.enable = false;
      info.enable = false;
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
        pinentry-curses
        sops
        trezor-agent
        trezorctl
        waypipe
        wireguard-tools
        wl-clipboard
        xdg-utils # open command
        xfsprogs
        xkbcomp
        xkcdpass
        xwayland-satellite
        yazi
        yubikey-manager
      ];
    };
    hardware = {
      enableRedistributableFirmware = true; # enables WiFi and GPU drivers
      bluetooth.enable = true; # https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/LE-Audio-+-LC3-support
      graphics.enable = true; # radv: an open-source Vulkan driver from freedesktop
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
        user.signingkey = "/home/juuso/.ssh/id_ed25519_sk_rk";
      };
    };
    services = {
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        # https://github.com/JManch/nixos/blob/38cbb86ff3e28dcb6116a05636548dc803e258dc/modules/nixos/system/audio.nix#L127-L159
        extraConfig.pipewire."99-input-denoising.conf" = {
          "context.modules" = lib.singleton {
            name = "libpipewire-module-filter-chain";
            args = {
              "node.description" = "Noise Canceling source";
              "media.name" = "Noise Canceling source";
              "filter.graph" = {
                nodes = lib.singleton {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                  label = "noise_suppressor_stereo";
                  control = {
                    "VAD Threshold (%)" = 50.0;
                    "VAD Grace Period (ms)" = 200;
                    "Retroactive VAD Grace (ms)" = 0;
                  };
                };
              };
              "capture.props" = {
                "node.description" = "RNNoise Sink";
                "node.name" = "capture.rnnoise_sink";
                "node.passive" = true;
                "audio.rate" = 48000;
              };
              "playback.props" = {
                "node.description" = "RNNoise Stream";
                "node.name" = "rnnoise_stream";
                "media.class" = "Audio/Source";
                "audio.rate" = 48000;
              };
            };
          };
        };
      };
      speechd.enable = lib.mkForce false; # https://github.com/NixOS/nixpkgs/pull/330440#issuecomment-2369082964
      trezord.enable = true;
      yubikey-agent.enable = true;
    };
  };
}
