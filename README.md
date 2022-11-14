# nix-config
My personal NixOS config

## Dockerfiles

E.g., to build the graphical version, run:

1. `cp graphical.nix default.nix`

2. `podman build . --tag graphical`

3. `podman run -v "$PWD:$PWD":z -w "$PWD" graphical`

4. `sudo ./out/result/kexec-boot` (the system will kexec)
