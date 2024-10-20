{
  version = "v1";
  subnets = [
    {
      name = "hetzner";
      endpoints = [
        { }
      ];
    }
  ];
  peers = [
    {
      name = "matrix";
      subnets = {
        hetzner = {
          listenPort = 51820;
          # no ipAddresses field will auto generate an IPv6 address
        };
      };
      endpoints = [
        {
          # no match can be any
          port = 51820;
          ip = "matrix.ponkila.com";
        }
      ];
    }
    {
      name = "muro";
      subnets = {
        hetzner = {
          listenPort = 51822;
        };
      };
      endpoints = [
        {
          # no match field means match all peers
          port = 51822;
          ip = "muro.ponkila.intra";
        }
      ];
    }
  ];
  connections = [
    {
      a = [{ type = "subnet"; rule = "is"; value = "hetzner"; }];
      b = [{ type = "subnet"; rule = "is"; value = "hetzner"; }];
      subnets = [ "hetzner" ];
    }
  ];
}
