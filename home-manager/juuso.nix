{ inputs
, config
, pkgs
, lib
, ...
}:
{

  home-manager.users.juuso = { pkgs, ... }: {

    home.stateVersion = "23.05";

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
      discord
    ];

    programs.mpv.enable = true;

    programs.fish = with config.home-manager.users.juuso; {
      enable = true;
      loginShellInit = ''
        ${if pkgs.system == "aarch64-darwin" then
          "set -x ponkila (getconf DARWIN_USER_TEMP_DIR)${sops.secrets."wireguard/ponkila.conf".name}"
        else ""}
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
      '';
    };

    programs.tmux = {
      enable = true;
      baseIndex = 1;
      plugins = with pkgs.tmuxPlugins; [
        extrakto # Ctrl+a+Tab
        tilish # Option+Enter
        tmux-fzf # Ctrl+a+Shift+f
      ];
      extraConfig = ''
        set -g @tilish-dmenu 'on'
        set -g mouse on

        bind | split-window -h
        unbind %

        set -g focus-events on
        set-option -g default-shell "${lib.getExe pkgs.fish}"
      '';
      shortcut = "a";
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
      ];
    };
  };

}
