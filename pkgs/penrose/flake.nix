{
  description = "Minimal rust wasm32-unknown-unknown example";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ rust-overlay.overlay ];
        pkgs = import nixpkgs { inherit system overlays; };
        rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        inputs = with pkgs; [
          cairo
          giflib
          libjpeg
          libpng
          librsvg
          nodePackages.node-pre-gyp
          nodejs
          pango
          pixman
          pkg-config
          python310Full
          rust
          wasm-bindgen-cli
          yarn
        ] ++ lib.optionals stdenv.isDarwin [
          darwin.apple_sdk.frameworks.CoreText
        ];
      in
      {
        defaultPackage = pkgs.rustPlatform.buildRustPackage {
          pname = "penrose";
          version = "1.0.0";

          src = pkgs.fetchFromGitHub {
            owner = "jhvst";
            repo = "penrose";
            rev = "main";
            sha256 = "sha256-0nL1SnRPQuwpzzfTCpGQRMt0jynQ7+SiKkrDZLoQrDE=";
          };

          cargoHash = "sha256-xI5Hu+N3CdTc+ZZGir6CviHhBJp11qJJDIahy2EPHU0=";

          nativeBuildInputs = inputs;

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath inputs;

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
