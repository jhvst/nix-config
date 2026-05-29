# Originally from: https://github.com/foo-dogsquared/nixos-config
# The service does not seem to work directly -- you must run
# the binary as the user.
# Nevertheless, this sets up the requires services for the NixOS host.
{ config, lib, pkgs, ... }:

let cfg = config.services.uxplay;
in {
  options.services.uxplay = {
    enable = lib.mkEnableOption "uxplay, an Airplay mirroring server";

    package = lib.mkPackageOption pkgs "uxplay" { };

    extraArgs = lib.mkOption {
      type = with lib.types; listOf str;
      description = ''
        Extra arguments to passed onto the service executable.
      '';
      default = [ ];
      example = [ "-p" "4747" ];
    };
  };

  config = lib.mkIf cfg.enable {
    # UXPlay requires a DNS-SD server so we'll enable Avahi.
    services.avahi.enable = lib.mkDefault true;
    services.avahi.publish.enable = lib.mkDefault true;
    services.avahi.publish.userServices = lib.mkDefault true;

    # We also have enabled mDNS since we're already using Avahi anyways.
    services.avahi.nssmdns4 = lib.mkDefault true;
    services.avahi.nssmdns6 = lib.mkDefault true;

    security.rtkit.enable = true;
  };
}
