{ buildGoModule
, fetchFromGitHub
, go
, lib
,
}:
buildGoModule rec {
  pname = "es-node";
  version = "0.1.12";

  src = fetchFromGitHub {
    owner = "ethstorage";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-WvBXZajkshCAIrVj4rR4Ix1M7uvPZhGUXdj0r38KVao=";
  };

  vendorHash = "sha256-c0MlQngiyDrpTLw+pNcD4mo8GFtEabjSLVVRrXG2eC8=";

  checkFlags = [
    # Mining requires L1 endpoint, prover tests need zkeys (500MB blobs)
    "-skip=TestMining|TestKZGProver_GenerateKZGProof|TestZKProver_GenerateZKProofPerSample|TestZKProver_GenerateZKProof"
  ];

  postInstall = ''
    # https://github.com/ethstorage/es-node/blob/838d1126f939c65a06379fa28c81f6a322285090/Makefile
    mkdir -p $out/lib/{snarkjs,snarkbuild}
    cp -r $src/ethstorage/prover/snarkjs $out/lib/snarkjs
  '';

  meta = with lib; {
    description = "Golang implementation of the EthStorage node.";
    homepage = "https://github.com/ethstorage/es-node";
    license = with licenses; [ bsl11 ];
    mainProgram = "es-node";
    inherit (go.meta) platforms;
  };
}

