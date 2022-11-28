self: super:
{
  linuxPackagesFor = kernel: (super.linuxPackagesFor kernel).extend (_: _: {
    patches = super.patches ++ [
      ./patches/kexex.patch
    ];
  });
}
