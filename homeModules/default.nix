{ config
, ...
}:
{
  options = { };
  config = {
    home-manager.users.juuso = _: {
      home.stateVersion = config.system.stateVersion;
      programs = {
        mergiraf.enable = true;
        ssh = {
          enable = true;
          matchBlocks."*" = {
            hashKnownHosts = true;
            identityFile = "~/.ssh/id_ed25519_sk_rk";
          };
        };
      };
      services.mako.enable = true;
    };
  };
}
