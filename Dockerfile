FROM docker.io/nixos/nix

ARG hostname
ENV BUILD_ME=$hostname

RUN echo "extra-experimental-features = flakes nix-command" > /etc/nix/nix.conf \
    && echo "accept-flake-config = true" >> /etc/nix/nix.conf

CMD nix develop && nix build .#$BUILD_ME \
    && rsync -L -r result out && unlink result
