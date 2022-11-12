# nix-build -A pix.ipxe minimal.nix -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.zip

{ system ? "x86_64-linux"
, nixpkgs ? import <nixpkgs> { }
, nixos ? import <nixpkgs/nixos> { }
,
}:

let

  juuso = builtins.fetchTarball "https://github.com/jhvst/nix-config/archive/refs/heads/main.zip";

  nixosWNetBoot = import <nixpkgs/nixos> {

    configuration = { config, pkgs, lib, ... }: with lib; {

      imports = [
        (import "${juuso}/system/netboot.nix")
        (import "${juuso}/system/ramdisk.nix")
      ];

      boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

      services.getty.autologinUser = "nixos";
      users.users.nixos = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          # "ssh-rsa ..."
        ];
        ## Allow the graphical user to login without password
        initialHashedPassword = "";
      };
      users.users.root.initialHashedPassword = "";

      security.sudo = {
        enable = mkDefault true;
        wheelNeedsPassword = mkForce false;
      };
      services.openssh.enable = true;
    };
  };

  mkNetboot = nixpkgs.pkgs.symlinkJoin {
    name = "netboot";
    paths = with nixosWNetBoot.config.system.build; [ netbootRamdisk kernel netbootIpxeScript kexecTree ];
    preferLocalBuild = true;
  };

in
{ pix.ipxe = mkNetboot; }
