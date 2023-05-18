{ config
, pkgs
, modulesPath
, ...
}:
{
  # Create the squashfs image that contains the Nix store.
  system.build.squashfsStore = pkgs.callPackage "${toString modulesPath}/../lib/make-squashfs.nix" {
    # Closures to be copied to the Nix store, namely the init
    # script and the top-level system configuration directory.
    storeContents = [ config.system.build.toplevel ];
  };

  # Create the initrd
  system.build.netbootRamdisk = pkgs.makeInitrdNG {
    compressor = "zstd";
    prepend = [ "${config.system.build.initialRamdisk}/initrd" ];
    contents = [{
      object = config.system.build.squashfsStore;
      symlink = "/nix-store.squashfs";
    }];
  };

  system.build.netbootIpxeScript = pkgs.writeTextDir "netboot.ipxe" ''
    #!ipxe
    # Use the cmdline variable to allow the user to specify custom kernel params
    # when chainloading this script from other iPXE scripts like netboot.xyz
    kernel ${pkgs.stdenv.hostPlatform.linux-kernel.target} init=${config.system.build.toplevel}/init initrd=initrd ${toString config.boot.kernelParams} ''${cmdline}
    initrd initrd
    boot
  '';

  # A script invoking kexec on ./bzImage and ./initrd.gz.
  # Usually used through system.build.kexecTree, but exposed here for composability.
  system.build.kexecScript = pkgs.writeScript "kexec-boot" ''
    #!/usr/bin/env bash
    if ! kexec -v >/dev/null 2>&1; then
      echo "kexec not found: please install kexec-tools" 2>&1
      exit 1
    fi
    SCRIPT_DIR=$( cd -- "$( dirname -- "''${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    kexec --load ''${SCRIPT_DIR}/bzImage \
      --initrd=''${SCRIPT_DIR}/initrd.gz \
      --command-line "init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}"
    systemctl kexec
  '';

  # A tree containing initrd.gz, bzImage and a kexec-boot script.
  system.build.kexecTree = pkgs.linkFarm "kexec-tree" [
    {
      name = "initrd.gz";
      path = "${config.system.build.netbootRamdisk}/initrd";
    }
    {
      name = "bzImage";
      path = "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}";
    }
    {
      name = "kexec-boot";
      path = config.system.build.kexecScript;
    }
  ];
}
