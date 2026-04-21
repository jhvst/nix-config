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
        papis = {
          enable = true;
          libraries."papers" = {
            isDefault = true;
            settings = {
              dir = "/var/lib/papis";
            };
          };
          settings = {
            add-edit = true;
          };
        };
        ssh = {
          enable = true;
          enableDefaultConfig = false;
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
