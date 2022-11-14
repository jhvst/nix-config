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
        (self: super: {
          mesa = super.mesa.overrideAttrs (old: {
            version = "trunk";
            src = super.fetchFromGitHub {
              owner = "Mesa3D";
              repo = "mesa";
              rev = "71c4543af1ad7b2b51f18140373b8756c1631d07";
              # If you don't know the hash, the first time, set:
              # sha256 = "0000000000000000000000000000000000000000000000000000";
              # then nix will fail the build with such an error message:
              # hash mismatch in fixed-output derivation '/nix/store/m1ga09c0z1a6n7rj8ky3s31dpgalsn0n-source':
              # wanted: sha256:0000000000000000000000000000000000000000000000000000
              # got:    sha256:173gxk0ymiw94glyjzjizp8bv8g72gwkjhacigd1an09jshdrjb4
              sha256 = "w4J59afHu8OSy1DqDtTEEsm1ELfZk8LDdNPsSpyjN8U=";
            };
            patches = [
              ./patches/opencl.patch
              ./patches/disk_cache-include-dri-driver-path-in-cache-key.patch
            ];
            buildInputs = old.buildInputs ++ [ super.glslang ];
            # see: https://github.com/Mesa3D/mesa/commit/8cc766d8f7eac26b7c029a2fac1bdfdba4776c29
            mesonFlags = lib.remove (lib.findFirst (x: (lib.hasPrefix "-Dxvmc" x)) "" old.mesonFlags) old.mesonFlags;
          });
        })
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
