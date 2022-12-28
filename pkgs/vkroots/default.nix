{ stdenv
, fetchFromGitHub
, meson
, pkg-config
, ninja
, vulkan-headers
, ...
}:

stdenv.mkDerivation rec {
  pname = "vkroots";
  version = "a7ee30d527231f7b8798c20c22345a79e8b8caac";
  src = fetchFromGitHub {
    owner = "Scrumplex";
    repo = pname;
    rev = version;
    sha256 = "sha256-dwKqHDuDBFXKp+X6H9vVplf546sI1j6WulxWN99xaBM=";
  };
  meta.homepage = "https://github.com/Joshua-Ashton/vkroots";

  nativeBuildInputs = [ meson pkg-config ninja ];

  buildInputs = [ vulkan-headers ];

}
