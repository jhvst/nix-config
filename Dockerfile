FROM nixos/nix

RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable
RUN nix-channel --update
RUN nix-env -iA nixpkgs.rsync

CMD nix-build -A pix.ipxe && rsync -L -r result out && unlink result