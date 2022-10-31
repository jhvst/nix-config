{
    config,
    pkgs,
    lib,
    ...
}:
{
    imports = [ <home-manager/nixos> ];

    users.users.core = {
        isNormalUser = true;
        group = "core";
        extraGroups = [ "wheel" "networkmanager" "video" ];
        openssh.authorizedKeys.keys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCuc2L4Q39X4y/pYNpd4hb4UuDUdjzv+z/mFELSsHGzPFDpS0H+TbCj6tVGqsk/sF+KBDb9HKxZvEMGyJokcxirnlWjYeRblgvOxVeEjJbnvwtlw3NCsI901fRCBzU9Un0jnuQAzPkv/NjJs2bz9CKSoDEvGq2SGLE5jTAUJSaHf9BGaZIkf5IjTzqurekdeBy7aZkm3j1DEeKJxOONgfqDsD3owKVLBLtf1Rnf19rZYGAnXMQlQSb3Tdn921fB77nrUIsi1ImBVok5fOrSjiPWBEDPl+Xik3H1ru1X+dB3AQhsAvICt3IUbm1+1yP4aoEu2n+Q4I7qnjlzBehO5/S3Sv3RdxwNic6upHH1bDfHMcMMc4BQqjSnDqOWPi7yC2JPKm0A5ihw/3rxLr0RTX76IbqMqjbyP9210znlfVu8pG4e7aDkioTy4rgEfd+BnfrMtb9gzb9VvXWGS4Togi8xHm0s2Kms0QuozJ+LTNgQcaGJLl/I8AW4vVh8NSoR8ki/60ayWunO+FtbBlUtFSlC5wkuELNxU9nYWenlNQG3CnjCsebj3lnQDsdQMgRqnyWNcw/AJrIs6LE7/8nmRTWd3TwIL51gd+Yj7ONMNYK0ja+h4LxB93YGwEpfeSfXZjNlQNyV8gLxrdqtMzzFuNn/re0jKAVCCD+lvix5+lzYpQ== Juuso’siPhone"
        ];
        shell = pkgs.fish;
    };
    users.groups.core = {};
    environment.shells = [ pkgs.fish ];

    home-manager.users.core = { pkgs, ... }: {

        home.packages = with pkgs; [
            file
            tree
            bind # nslookup
        ];

        programs = {
            tmux.enable = true;
            htop.enable = true;
            vim.enable = true;
            git.enable = true;
            fish.enable = true;
            fish.loginShellInit = "fish_add_path --move --prepend --path $HOME/.nix-profile/bin /run/wrappers/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin";

            home-manager.enable = true;
        };

        home.stateVersion = "22.11";
    };
    home-manager.useUserPackages = true;
    home-manager.useGlobalPkgs = true;
}