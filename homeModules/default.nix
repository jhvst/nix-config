{ config
, ...
}:
{
  options = { };
  config = {
    home-manager.users.juuso = _: {
      home.stateVersion = config.system.stateVersion;

      services.mako.enable = true;
    };
  };
}
