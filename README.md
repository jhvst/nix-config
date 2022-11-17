# nix-config
My personal NixOS config

## Dockerfiles

E.g., to build the graphical version, run:

1. `cp graphical.nix default.nix`

2. `podman build . --tag graphical`

3. `podman run -v "$PWD:$PWD":z -w "$PWD" graphical`

4. `sudo ./out/result/kexec-boot` (the system will kexec)

## NixOS

### Useful links

- https://www.reddit.com/r/NixOS/comments/g77n4m/run_sway_on_startup/
- https://github.com/nix-community/nixos-generators
- https://gist.github.com/nh2/b7d285a7530603c2fe0b426fbb3da350

### three-phased booting:
- https://github.com/systemd/mkosi
- https://systemd.io/BUILDING_IMAGES/
- https://unix.stackexchange.com/questions/539359/passing-default-target-to-systemd-with-systemctl-switch-root
- https://blog.6aa4fd.com/post/ipxe-nix-ci/

### Game streaming
- https://old.reddit.com/r/linux_gaming/comments/w4i3qf/easy_way_to_get_good_4k_60fps_obs_encoding/
