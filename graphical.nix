# nix-build -A pix.ipxe graphical.nix -I home-manager=https://github.com/nix-community/home-manager/archive/master.tar.gz -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.zip

{ system ? "x86_64-linux"
, nixpkgs ? import <nixpkgs> { }
, nixos ? import <nixpkgs/nixos> { }
,
}:

let

  juuso = builtins.fetchTarball "https://github.com/jhvst/nix-config/archive/refs/heads/main.zip";

  nixosWNetBoot = import <nixpkgs/nixos> {

    configuration = { config, pkgs, lib, ... }: with lib; {

      nixpkgs.overlays = [
        (import overlays/mesa.nix)
      ];

      imports = [
        (import "${juuso}/system/netboot.nix")
        (import "${juuso}/system/ramdisk.nix")
      ];

      boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

      services.getty.autologinUser = "nixos";
      users.users.nixos = {
        isNormalUser = true;
        extraGroups = [ "wheel" "video" ];
        openssh.authorizedKeys.keys = [
          # "ssh-rsa ..."
        ];
        ## Allow the graphical user to login without password
        initialHashedPassword = "";
      };
      users.users.root.initialHashedPassword = "";

      networking.firewall.enable = false;

      environment.systemPackages = with pkgs; [
        kexec-tools
        vulkan-tools
      ];

      hardware.opengl = {
        driSupport = true;
        driSupport32Bit = true;
      };

      ## Window manager
      programs.sway.enable = true;
      environment.loginShellInit = ''
        [[ "$(tty)" == /dev/tty1 ]] && sway
      '';

      ## Firmware blobs
      hardware.enableRedistributableFirmware = true;
    };
  };

  mkNetboot = nixpkgs.pkgs.symlinkJoin {
    name = "netboot";
    paths = with nixosWNetBoot.config.system.build; [ kexecTree ];
    preferLocalBuild = true;
  };

in
{ pix.ipxe = mkNetboot; }
