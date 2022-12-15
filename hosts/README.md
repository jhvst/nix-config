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

