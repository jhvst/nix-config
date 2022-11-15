self: super: with super.lib; {
  mesa = super.mesa.overrideAttrs (old: {
    version = "trunk";
    src = super.fetchFromGitHub {
      owner = "Mesa3D";
      repo = "mesa";
      rev = "71c4543af1ad7b2b51f18140373b8756c1631d07";
      # If you don't know the hash, the first time, set:
      # sha256 = "0000000000000000000000000000000000000000000000000000";
      # then nix will fail the build with such an error message:
      # hash mismatch in fixed-output derivation '/nix/store/m1ga09c0z1a6n7rj8ky3s31dpgalsn0n-source':
      # wanted: sha256:0000000000000000000000000000000000000000000000000000
      # got:    sha256:173gxk0ymiw94glyjzjizp8bv8g72gwkjhacigd1an09jshdrjb4
      sha256 = "w4J59afHu8OSy1DqDtTEEsm1ELfZk8LDdNPsSpyjN8U=";
    };
    patches = [
      ./patches/opencl.patch
      ./patches/disk_cache-include-dri-driver-path-in-cache-key.patch
    ];
    buildInputs = old.buildInputs ++ [ super.glslang ];
    mesonFlags = remove (findFirst (x: (hasPrefix "-Dxvmc" x)) "" old.mesonFlags) old.mesonFlags;
  });
}
