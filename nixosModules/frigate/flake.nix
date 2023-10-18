{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
    libedgetpu.url = "github:jhvst/nix-flake-edgetpu";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    { self
    , nixpkgs
    , libedgetpu
    , flake-parts
    , ...
    }@inputs:

    flake-parts.lib.mkFlake { inherit inputs; } rec {

      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      perSystem = { pkgs, lib, config, system, ... }: {

        overlayAttrs = {
          inherit (config.packages) frigate;
        };

        packages = {
          frigate = pkgs.frigate.overrideAttrs (oldAttrs: {
            LD_LIBRARY_PATH = "${config.packages.libedgetpu}/lib";
            buildInputs = oldAttrs.buildInputs ++ [ config.packages.libedgetpu ];
            propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [ config.packages.libedgetpu ];
          });
          libedgetpu = libedgetpu.packages.${system}.libedgetpu;
        };

        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

      };

      flake =
        let
          inherit (self) outputs;
        in
        {

          nixosConfigurations = {
            container = nixpkgs.lib.nixosSystem {

              specialArgs = { inherit inputs outputs; };
              system = "x86_64-linux";
              modules =
                [
                  ({ pkgs, lib, outputs, ... }: {

                    boot.isContainer = true;
                    system.stateVersion = "23.05";

                    environment.systemPackages = [
                      outputs.packages.${pkgs.system}.libedgetpu
                    ];

                    services.frigate = {
                      enable = true;
                      package = outputs.packages.${pkgs.system}.frigate;
                      hostname = "frigate.ponkila.periferia";
                      settings = {
                        detectors = {
                          coral = {
                            type = "edgetpu";
                            device = "usb";
                          };
                        };
                        cameras = { };
                      };
                    };

                    networking.useDHCP = false;
                    networking = {
                      firewall = {
                        enable = true;
                        allowedTCPPorts = [ 80 ];
                      };
                      # Use systemd-resolved inside the container
                      useHostResolvConf = lib.mkForce false;
                    };

                    services.resolved.enable = true;

                  })
                ];
            };

          };


        };
    };
}
