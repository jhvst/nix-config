# https://xyno.space/post/nix-darwin-introduction
# https://github.com/Misterio77/nix-starter-configs/tree/main/standard
{

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # nix will normally use the nixpkgs defined in home-managers inputs, we only want one copy of nixpkgs though
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs"; # ...
  };

  # add the inputs declared above to the argument attribute set
  outputs = { self, nixpkgs, home-manager, darwin }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    rec {

      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; }
      );

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      ### --- configure nixpkgs
      config = {
        allowUnfree = true;
      };

      darwinConfigurations."sandbox" = darwin.lib.darwinSystem {
        # you can have multiple darwinConfigurations per flake, one per hostname

        specialArgs = { inherit inputs outputs; };
        system = "aarch64-darwin"; # "x86_64-darwin" if you're using a pre M1 mac
        modules = [
          home-manager.darwinModules.home-manager
          ./hosts/sandbox/default.nix
        ];
      };
    };
}
