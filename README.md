# nix-config

### Background

A prominent direction in the Linux distribution scene lately has been the concept of _immutable_ desktop operating systems. Recent examples include [Fedora Silverblue](https://silverblue.fedoraproject.org) (2018) and [Vanilla OS](https://vanillaos.org) (2022). But, on my anecdotal understanding of the timelines concerning Linux distros, both are spiritual successors to [CoreOS](https://coreos.com/) (2013).

The first time the concepts of CoreOS extended to a desktop system came to my radar was [in a blog post by Jessie Frazelle](https://blog.jessfraz.com/post/ultimate-linux-on-the-desktop/) (2017). Here, Jessie modified the base image of CoreOS using Gentoo `emerge` to include graphics drivers. To a vast extent, this project does the same but with [NixOS](https://nixos.org).

But there's more to my approach to operating systems than immutability: _ephemerality_. In NixOS circles, ephemerality is arguably more widely known as the concept of [erasing your darlings](https://grahamc.com/blog/erase-your-darlings/), as blogged by Graham Christensen (2020). NixOS has tooling around maintaining these kinds of temporary Linux root filesystems, most notably, [impermanence](https://github.com/nix-community/impermanence). In effect, these approaches help to maintain a reproducible Linux distribution by ensuring that the NixOS configuration is _verbatim_ (Finnish: _sanansamukainen_) of the running system. Otherwise, undocumented state changes may creep into the system over time, hence mangling the difference between what is part of the OS and what is part of the user configuration. Over time, this demeans the point of using NixOS in the first place.

Another approach to a clean root filesystem is to delete the whole OS. This is the approach that I switched to in 2021 after reading [Running Fedora CoreOS directly from RAM](https://docs.fedoraproject.org/en-US/fedora-coreos/live-booting/). Historically, these so-called _live-boot_ environments have been around for a long time in the form of Preboot eXecution Environments (PXEs). For example, most university and library computers boot using PXE. Technically speaking, what happens is that the BIOS of the computer asks a DHCP server for an operating system to start. The DHCP server then points to a TFTP server from which the boot files are loaded on put into RAM. When the computer shuts down, the RAM is cleared, hence the OS state destroyed. Coincidentally, I like this approach because it avoids needing a separate boot manager -- the "boot manager" is a PXE text file on the TFTP server.  Before moving to NixOS in 2022, I maintained configuration files for this kind of system on a GitHub project [`stateless-fcos`](https://github.com/jhvst/stateless-fcos).

The timeline now continues from this repository in the form of NixOS configurations. Spiritually, it is a successor of both CoreOS and Jessie's graphical CoreOS. And what made the switch for me was that I initially wanted the graphics drivers for my [`rivi-loader`](https://github.com/periferia-labs/rivi-loader) project. The idea was that my CoreOS server would also act as a remote GPU computing host for my own programming language, which I call Rivi.

What made getting into NixOS particularly easy was that my CoreOS server was already reproducible from `ignition` configurations. Further, everything ran in a `podman` container. So, to make the initial switch to NixOS, I merely had to translate the `systemd` processes from `ignition` to NixOS option format.

### Useful links

- https://www.reddit.com/r/NixOS/comments/g77n4m/run_sway_on_startup/
- https://gist.github.com/nh2/b7d285a7530603c2fe0b426fbb3da350

### three-phased booting:
- https://github.com/systemd/mkosi
- https://systemd.io/BUILDING_IMAGES/
- https://unix.stackexchange.com/questions/539359/passing-default-target-to-systemd-with-systemctl-switch-root
- https://blog.6aa4fd.com/post/ipxe-nix-ci/

### Game streaming
- https://old.reddit.com/r/linux_gaming/comments/w4i3qf/easy_way_to_get_good_4k_60fps_obs_encoding/
