{ buildNpmPackage
, esbuild
, fetchFromGitHub
}: buildNpmPackage rec {

  pname = "fstar-vscode-assistant";
  version = "0.15.1";
  sourceRoot = "${src.name}/lspserver";

  src = fetchFromGitHub {
    owner = "FStarLang";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-yT7w7Oa8OARSFOIcB6xAAHGBxUdCqksjOMYl1vs8cwE=";
  };

  npmDepsHash = "sha256-haI7ZxRRtH8HQQmEmFrgQFMVkAwrUlae6naJPYwa+G8=";

  npmBuildScript = "compile";

  nativeBuildInputs = [ esbuild ];

}
