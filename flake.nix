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
    ponkila.url = "git+ssh://git@github.com/jhvst/ponkila";
    bqnlsp.url = "sourcehut:~detegr/bqnlsp";
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
    , ponkila
    , bqnlsp
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

      muro = {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./home-manager/juuso.nix
          ./home-manager/programs/neovim
          ./hosts/muro
          ./nix-settings.nix
          ./system/ramdisk.nix
          ponkila.nixosModules.muro
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
          }
        ];
        customFormats = customFormats;
        format = "kexecTree";
      };

      starlabs = {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./home-manager/juuso.nix
          ./home-manager/programs/neovim
          ./hosts/starlabs
          ./nix-settings.nix
          ./system/ramdisk.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
          }
        ];
        customFormats = customFormats;
        format = "kexecTree";
      };

      amd = {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [ ./hosts/amd ];
        customFormats = customFormats;
        format = "kexecTree";
      };

      host-darwin = {
        specialArgs = { inherit inputs outputs; };
        system = "aarch64-darwin"; # "x86_64-darwin" if you're using a pre M1 mac
        modules = [
          ./home-manager/juuso.nix
          ./home-manager/programs/neovim
          ./hosts/darwin
          ./nix-settings.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.sharedModules = [
              sops-nix.homeManagerModules.sops
            ];
            home-manager.useGlobalPkgs = true;
          }
        ];
      };

    in
    {

      formatter = forAllSystems (system:
        nixpkgs.legacyPackages.${system}.nixpkgs-fmt
      );

      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; }
      );

      # nixos-generators
      "amd" = nixos-generators.nixosGenerate amd;
      "starlabs" = nixos-generators.nixosGenerate starlabs;
      "muro" = nixos-generators.nixosGenerate muro;

      # Devshell for bootstrapping
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./shell.nix { inherit pkgs; }
      );

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      nixosConfigurations = with nixpkgs.lib; {
        "starlabs" = nixosSystem (getAttrs [ "system" "specialArgs" "modules" ] starlabs);
        "muro" = nixosSystem (getAttrs [ "system" "specialArgs" "modules" ] muro);
        "amd" = nixosSystem (getAttrs [ "system" "specialArgs" "modules" ] amd);
      };

      darwinConfigurations = with darwin.lib; {
        "host-darwin" = darwinSystem host-darwin;
      };
    };
}
