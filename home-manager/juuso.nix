{ inputs
, config
, pkgs
, lib
, ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  users.users.juuso = {
    isNormalUser = true;
    group = "juuso";
    extraGroups = [ "wheel" "networkmanager" "video" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMKgTTpGSvPG4p8pRUWg1kqnP9zPKybTHQ0+Q/noY5+M6uOxkLy7FqUIEFUT9ZS/fflLlC/AlJsFBU212UzobA= ssh@secretive.sandbox.local"
    ];
    shell = pkgs.fish;
  };
  users.groups.juuso = { };
  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;

  home-manager.users.juuso = { pkgs, ... }: {

    home.packages = with pkgs; [
      file
      tree
      bind # nslookup
    ];

    programs.nix-index.enable = true;
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.firefox.enable = true;

    services.clipman.enable = true;

    programs = {
      tmux.enable = true;
      htop.enable = true;
      vim.enable = true;
      git.enable = true;
      fish.enable = true;
      fish.loginShellInit = "fish_add_path --move --prepend --path $HOME/.nix-profile/bin /run/wrappers/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin";

      home-manager.enable = true;
    };

    home.stateVersion = "23.05";
  };
}
