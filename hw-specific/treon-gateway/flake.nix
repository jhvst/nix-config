{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/22.11";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-generators, ... }@inputs:
    let
      inherit (self) outputs;
      customFormats = {
        "kexecTree" = {
          formatAttr = "kexecTree";
          imports = [ ./netboot.nix ];
        };
      };
    in
    {

      packages.armv7l-linux.kexec-tools = nixpkgs.legacyPackages.armv7l-linux.pkgsStatic.kexec-tools;

      packages.aarch64-darwin.psutil = nixpkgs.legacyPackages.armv7l-linux.python310Packages.psutil.overrideAttrs (old: {
        disabledTests = old.disabledTests ++ [ "test_disk_partitions" ];
      });

      packages.x86_64-linux.default = self.packages.armv7l-linux.kexec-tools;

      "minimal" = nixos-generators.nixosGenerate {
        specialArgs = { inherit inputs outputs; };
        system = "armv7l-linux";
        modules = [
          ./minimal.nix
          ./ramdisk.nix
          {
            nixpkgs.overlays = [
              (self: super: {
                python310 = super.python310.override {
                  packageOverrides = pyself: pysuper: {
                    psutil = pysuper.psutil.overrideAttrs (old: {
                      disabledTests = old.disabledTests ++ [ "test_disk_partitions" ];
                    });
                    mypy = pysuper.mypy.overrideAttrs (old: with super.lib; {
                      doCheck = false;
                      pythonImportsCheck = remove (findFirst (x: (hasPrefix "mypy.report" x)) "" old.pythonImportsCheck) old.pythonImportsCheck;
                    });
                  };
                };
              })
            ];
          }
        ];
        customFormats = customFormats;
        format = "kexecTree";
      };

      nixosConfigurations.minimal = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        system = "armv7l-linux";
        modules = [
          ./minimal.nix
          {
            nixpkgs.overlays = [
              (self: super: {

                python310 = super.python310.override {
                  packageOverrides = pyself: pysuper: {
                    psutil = pysuper.psutil.overrideAttrs (old: {
                      disabledTests = old.disabledTests ++ [ "test_disk_partitions" ];
                    });

                  };
                };

              })
              (self: super: {
                mypy = super.mypy.overrideAttrs (old: {
                  doCheck = false;
                });
              })
            ];
          }
        ];
      };

    };
}
