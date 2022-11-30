self: super: with super.lib; {
  mesa = super.mesa.overrideAttrs (old: {
    version = "22.3.0-rc4";
    src = super.fetchFromGitHub {
      owner = "Mesa3D";
      repo = "mesa";
      rev = "mesa-22.3.0-rc4";
      # If you don't know the hash, the first time, set:
      # sha256 = "0000000000000000000000000000000000000000000000000000";
      # then nix will fail the build with such an error message:
      # hash mismatch in fixed-output derivation '/nix/store/m1ga09c0z1a6n7rj8ky3s31dpgalsn0n-source':
      # wanted: sha256:0000000000000000000000000000000000000000000000000000
      # got:    sha256:173gxk0ymiw94glyjzjizp8bv8g72gwkjhacigd1an09jshdrjb4
      sha256 = "UO4+tWlymP3Pqx9HHv9nNkZz7tBCeOpjKHTC7+UNQZA=";
    };
    patches = [
      ./patches/opencl.patch
      ./patches/disk_cache-include-dri-driver-path-in-cache-key.patch
    ];
    buildInputs = old.buildInputs ++ [ super.glslang ];
    mesonFlags = remove (findFirst (x: (hasPrefix "-Dxvmc" x)) "" old.mesonFlags) old.mesonFlags;
  });
}
