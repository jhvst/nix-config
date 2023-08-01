{
  description = "Minimal rust wasm32-unknown-unknown example";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ rust-overlay.overlay ];
        pkgs = import nixpkgs { inherit system overlays; };
        rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        inputs = with pkgs; [
          cairo
          darwin.apple_sdk.frameworks.CoreText
          giflib
          libjpeg
          libpng
          librsvg
          nodejs
          pango
          pixman
          pkg-config
          python310Full
          rust
          wasm-bindgen-cli
          yarn
        ];
      in
      {
        defaultPackage = pkgs.rustPlatform.buildRustPackage {
          pname = "penrose";
          version = "1.0.0";

          src = ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
          };

          nativeBuildInputs = inputs;

          buildPhase = ''
            export HOME=$(pwd)
            yarn
            yarn build:roger
          '';
          installPhase = ''
            cp -r packages/roger/bin $out/bin
            cp -r packages/roger/dist $out/dist
          '';
        };


        devShell = pkgs.mkShell { packages = inputs; };
      }
    );
}
