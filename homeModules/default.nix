{ config
, ...
}:
{
  options = { };
  config = {
    home-manager.users.juuso = _: {
      home.stateVersion = config.system.stateVersion;
      programs.mergiraf.enable = true;
      services.mako.enable = true;
    };
  };
}
