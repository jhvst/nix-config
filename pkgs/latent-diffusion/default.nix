{ callPackage
, lib
, stdenv
, fetchFromGitHub
, testers
, pkgs
}:

let

  clip = pkgs.python39Packages.buildPythonPackage {
    pname = "clip";
    version = "trunk";

    propagatedBuildInputs = with pkgs.python39Packages; [
      ftfy
      regex
      tqdm
      pytorch
      torchvision
    ];

    src = fetchFromGitHub {
      owner = "openai";
      repo = "CLIP";
      rev = "d50d76daa670286dd6cacf3bcd80b5e4823fc8e1";
      sha256 = "GAitNBb5CzFVv2+Dky0VqSdrFIpKKtoAoyqeLoDaHO4=";
    };

    meta = {
      homepage = "https://github.com/pytoolz/toolz/";
      description = "List processing tools and functional utilities";
    };
  };

  taming = pkgs.python39Packages.buildPythonPackage {
    pname = "taming";
    version = "trunk";

    propagatedBuildInputs = with pkgs.python39Packages; [
      pytorch
      torchvision
      numpy

      #albumentations
      #opencv-python
      pudb
      imageio
      imageio-ffmpeg
      pytorch-lightning
      omegaconf
      test-tube
      #streamlit
      einops
      more-itertools
      transformers
    ];

    src = fetchFromGitHub {
      owner = "CompVis";
      repo = "taming-transformers";
      rev = "24268930bf1dce879235a7fddd0b2355b84d7ea6";
      sha256 = "kDChiuNh/lYO4M1Vj7fW3130kNl5wh+Os4MPBcaw1tM=";
    };

    meta = {
      homepage = "https://github.com/CompVis/taming-transformers/";
      description = "List processing tools and functional utilities";
    };
  };

in

stdenv.mkDerivation (finalAttrs: {
  pname = "latent-diffusion";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "jhvst";
    repo = "latent-diffusion";
    rev = "6fad37966f1f35b3ed44c773488746232979ef5d";
    sha256 = "3yhgDvSBmBGZkb0IbgxKuSM03cFFUJQA0X43SqFO4ZI=";
  };

  buildInputs = [
    pkgs.python39
    pkgs.python39.pkgs.pip
    pkgs.git
    pkgs.wget
  ];

  propagatedBuildInputs = with pkgs.python39Packages; [
    pytorch
    torchvision
    numpy

    #albumentations
    #opencv-python
    pudb
    imageio
    imageio-ffmpeg
    pytorch-lightning
    omegaconf
    test-tube
    #streamlit
    einops
    #torch-fidelity
    transformers

    taming
    clip
  ];

  configurePhase = ''
    #mkdir -p models/rdm/rdm768x768/
    #wget -O models/rdm/rdm768x768/model.ckpt https://ommer-lab.com/files/rdm/model.ckpt --no-check-certificate
    #pip3 install scann -t .
    #pip3 install albumentations opencv-python streamlit torch-fidelity -t .
  '';

  buildPhase = ''
    pip3 install kornia -t .
    #pip3 install albumentations==0.4.3 diffusers opencv-python==4.1.2.30 pudb==2019.2 invisible-watermark imageio==2.9.0 imageio-ffmpeg==0.4.2 pytorch-lightning==1.4.2 omegaconf==2.1.1 test-tube>=0.7.5 streamlit>=0.73.1 einops==0.3.0 torch-fidelity==0.3.0 transformers==4.19.2 torchmetrics==0.6.0 kornia==0.6 -t .
    #pip3 install -e git+https://github.com/CompVis/taming-transformers.git@master#egg=taming-transformers  -t . || true
    #pip3 install -e git+https://github.com/openai/CLIP.git@main#egg=clip -t .
    #python -m txt2img --prompt "a virus monster is playing guitar, oil on canvas" --ddim_eta 0.0 --n_samples 4 --n_iter 4 --scale 5.0  --ddim_steps 50
  '';

  doCheck = true;

  meta = with lib; {
    description = "A program that produces a familiar, friendly greeting";
    longDescription = ''
      GNU Hello is a program that prints "Hello, world!" when you run it.
      It is fully customizable.
    '';
    homepage = "https://www.gnu.org/software/hello/manual/";
    changelog = "https://git.savannah.gnu.org/cgit/hello.git/plain/NEWS?h=v${finalAttrs.version}";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.eelco ];
    platforms = platforms.all;
  };
})
