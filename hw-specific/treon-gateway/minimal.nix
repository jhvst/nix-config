{ config
, inputs
, lib
, pkgs
, ...
}:
{
  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;

      extra-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

    };
  };

  environment.systemPackages = with pkgs; [
    kexec-tools
  ];

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
  };

  security.sudo = {
    enable = lib.mkDefault true;
    wheelNeedsPassword = lib.mkForce false;
  };

  # networking.nftables.enable = true;
  # networking.firewall.enable = false;
  # services.dbus.implementation = "broker";
  environment.noXlibs = true;
  documentation.doc.enable = false;
  xdg.mime.enable = false;
  xdg.menus.enable = false;
  xdg.icons.enable = false;
  xdg.sounds.enable = false;
  xdg.autostart.enable = false;

  users.users.matti = {
    isNormalUser = true;
    group = "matti";
    extraGroups = [ "wheel" "networkmanager" "input" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMKgTTpGSvPG4p8pRUWg1kqnP9zPKybTHQ0+Q/noY5+M6uOxkLy7FqUIEFUT9ZS/fflLlC/AlJsFBU212UzobA= ssh@secretive.sandbox.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHj3vLFsh7urlvknDdUvdepe7T1TE96xwGeLwOnirAV+ parkkila.matti@gmail.com"
    ];
  };
  users.groups.matti = { };
}
