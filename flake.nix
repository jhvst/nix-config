# https://xyno.space/post/nix-darwin-introduction
# https://github.com/Misterio77/nix-starter-configs/tree/main/standard
# https://sourcegraph.com/github.com/shaunsingh/nix-darwin-dotfiles@8ce14d457f912f59645e167707c4d950ae1c3a6e/-/blob/flake.nix
{

  inputs = {
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    wayland.url = "github:nix-community/nixpkgs-wayland";
  };

  # add the inputs declared above to the argument attribute set
  outputs =
    { self
    , darwin
    , home-manager
    , nixos-generators
    , nixpkgs
    , sops-nix
    , wayland
    }@inputs:

    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      # custom formats for nixos-generators
      customFormats = {
        "kexecTree" = {
          formatAttr = "kexecTree";
          imports = [ ./system/netboot.nix ];
        };
      };
    in
    {

      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; }
      );

      # nixos-generators
      "amd" = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [ ./hosts/amd ];
        customFormats = customFormats;
        format = "kexecTree";
      };

      "starlabs" = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./home-manager/juuso.nix
          ./hosts/starlabs
          ./system/ramdisk.nix
          {
            nixpkgs.overlays = [ inputs.nixpkgs-wayland.overlay ];
          }
        ];
        customFormats = customFormats;
        format = "kexecTree";
      };

      # Devshell for bootstrapping
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./shell.nix { inherit pkgs; }
      );

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      darwinConfigurations."darwin" = darwin.lib.darwinSystem {
        # you can have multiple darwinConfigurations per flake, one per hostname

        specialArgs = { inherit inputs outputs; };
        system = "aarch64-darwin"; # "x86_64-darwin" if you're using a pre M1 mac
        modules = [
          ./hosts/darwin/default.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.sharedModules = [
              sops-nix.homeManagerModules.sops
            ];
          }
        ];
      };
    };
}
