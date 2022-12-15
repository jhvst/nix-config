# General notes

The easiest way to get started is likely to copy the repository so that you can change the values at will. You will at least have to find the mount commands found in the Nix files and the SSH public key in [`home-manager/core.nix`](https://github.com/jhvst/nix-config/blob/main/home-manager/core.nix).

## Building

Currently, cross-compilation is not supported. So, an x86 has to be built with x86 machine and an aarch64 one with an aarch64 machine. There are ways to remedy this, as documented in the [NixOS docs](https://nixos.org/guides/cross-compilation.html), but these have not been integrated. Once done, a Github action to be run in a private repository could be a good QoL improvement to get the images produced. Currently, the EL and CL layer use x86, and the VC is using aarhc64 on RPi 4.

The current options for building:
- use `nix` and run the command which is commented on the first line of each NixOS configuration
- use containers and the Dockerfile found from the parent folder to build the images

Eventually, [nixos-generators](https://github.com/nix-community/nixos-generators) should be used, but currently the targets expect the disk image to contain a persistent boot folder which a RAMdisk image does not have. This could be circumvented by adding a boot sector to the images which is simply the iPXE boot media.

## Booting

As these are RAMdisk installations (see, e.g. [CoreOS documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/live-booting/) for an introductory), the prominent approaches are:
- [iPXE](https://ipxe.org) e.g. via [netbootxyz](https://netboot.xyz). To elaborate, the build process produced a kernel, initial RAMdisk, and iPXE and kexec script. To see how to boot these over the network, do consult [Booting Methods](https://netboot.xyz/docs/category/booting-methods). To network-boot a Raspberry Pi is currently [complicated](https://github.com/jhvst/jhvst.github.io/blob/main/ipxe-rpi4.md), but I should eventually find the time to downstream these. Some useful scripts might already be found from my [CoreOS repository](https://github.com/jhvst/stateless-fcos) which includes Docker images for TFTP and DHCP servers.
- [kexec](https://www.man7.org/linux/man-pages/man8/kexec.8.html). E.g., one can build the image with a host OS, and then go to the artifact folder and execute the kexec script with superuser permission (`sudo ./kexec-boot`). This will halt the current system and boot into the new image without a power cycle. kexec is also a handy to be used when upgrading the servers. This is why the images ship with [`kexec-tools`](https://projects.horms.net/projects/kexec/kexec-tools/) pre-installed. A noteworthy remark is that if you run an external GPU for display output, this will likely be lost when doing a kexec hence you'll get a black screen only. A power cycle will restore GPU output.

# finland-north-1

This is an example config which uses bcachefs for Ethereum CL and EL

Currently, a number of assumptions are made:
- the disks are already formatted with bcachefs
- the Wireguard tunnel server is already configured
- JWT token has been initialized in the directories of both CL and EL

# finland-north-vc

This is an example config to run Ethereum validator

1. Build the image using some `aarch64-linux` machine
2. Boot the image either via iPXE or `kexec`
3. Plug-in and mount the device holding the validator keys. E.g., [WithSecure™ USB Armory](https://www.withsecure.com/en/solutions/innovative-security-hardware/usb-armory) formatted as [Armory Drive](https://github.com/usbarmory/armory-drive/wiki)
4. Import the validator keys: `lighthouse --network mainnet account validator import --directory /path/to/usb-armory/validator_keys`
5. Enable and start `lighthouse`: `sudo systemctl enable lighthouse`, and then `sudo systemctl start lighthouse`
6. You can now monitor the process with `sudo journalctl -u lighthouse` and the whole system with `sudo journalctl -f`

