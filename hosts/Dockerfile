FROM nixos/nix

RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable
RUN nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
RUN nix-channel --update
RUN nix-env -iA nixpkgs.rsync

CMD nix-build -A pix.ipxe && rsync -L -r result out && unlink result
