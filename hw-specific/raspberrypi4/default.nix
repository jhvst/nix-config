{
    pkgs,
    ...
}:
{
    boot.kernelPackages = pkgs.linuxPackages_rpi4;
    boot.loader.raspberryPi = {
        enable = true;
        version = 4;
    };
    boot.loader.grub.enable = false;
}