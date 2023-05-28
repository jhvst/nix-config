{ self
, lib
, pkgs
, ...
}: {

  # Allows this server to be used as a remote builder
  nix.settings.trusted-users = [
    "root"
    "@wheel"
  ];

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  networking.hostName = "muro";
  time.timeZone = "Europe/Helsinki";

  boot.kernelParams = [
    "boot.shell_on_fail"
    "ip=dhcp"

    "amdgpu.ppfeaturemask=0xffffffff"

    "mitigations=off"
    "l1tf=off"
    "mds=off"
    "no_stf_barrier"
    "noibpb"
    "noibrs"
    "nopti"
    "nospec_store_bypass_disable"
    "nospectre_v1"
    "nospectre_v2"
    "tsx=on"
    "tsx_async_abort=off"
  ];
  boot.kernelPatches = [{
    name = "CONFIG_SMB_SERVER";
    patch = null;
    extraConfig = ''
      SMB_SERVER m
    '';
  }];
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  users.users.juuso = {
    isNormalUser = true;
    group = "juuso";
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMKgTTpGSvPG4p8pRUWg1kqnP9zPKybTHQ0+Q/noY5+M6uOxkLy7FqUIEFUT9ZS/fflLlC/AlJsFBU212UzobA= ssh@secretive.sandbox.local"
    ];
    shell = pkgs.fish;
  };
  users.groups.juuso = { };
  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;

  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  zramSwap.memoryPercent = 100;

  security.sudo = {
    enable = lib.mkDefault true;
    wheelNeedsPassword = lib.mkForce false;
  };
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  networking.firewall.enable = false;

  ## Gaming start
  programs.steam.enable = false;
  programs.gamemode = {
    enable = false;
    settings = {
      general = {
        renice = 10;
      };

      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    fuse-overlayfs
    btrfs-progs
    ksmbd-tools
    lm_sensors
    nfs-utils

    # a Steam dependancy
    libblockdev
    # discord
    # Install and Update Proton-GE
    # https://github.com/GloriousEggroll/proton-ge-custom
    # README: https://github.com/AUNaseef/protonup
    # protonup --download
    protonup
    # A Vulkan and OpenGL overlay for monitoring FPS, temperatures, CPU/GPU load and more.
    # https://github.com/flightlessmango/MangoHud
    # To enable: MANGOHUD=1 MANGOHUD_CONFIG=full steam
    mangohud
    # debug utils for graphics
    # pkgs.glxinfo
    vulkan-tools
    # Upscaler
    # pkgs.vkBasalt
    # Mixer and audio control
    # easyeffects
    # helvum
    # pkgs.lutris
    # https://github.com/Plagman/gamescope
    # gamescope
  ];

  hardware.opengl = {
    ## radv: an open-source Vulkan driver from freedesktop
    driSupport = true;
    driSupport32Bit = true;

    ## amdvlk: an open-source Vulkan driver from AMD
    extraPackages = [ pkgs.amdvlk ];
    extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
  };
  hardware.steam-hardware.enable = true;
  hardware.xpadneo.enable = true;
  hardware.bluetooth.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  ### System APIs
  services.dbus.enable = true;

  ## Window manager
  programs.sway.enable = true;
  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';
  services.getty.autologinUser = "juuso";

  ## Firmware blobs
  hardware.enableRedistributableFirmware = true;

  systemd.mounts = [
    {
      enable = true;

      description = "local hdd storage";

      what = "/dev/disk/by-label/bakhal";
      where = "/var/mnt/bakhal";
      options = "compress=zstd:2,noatime";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
    {
      enable = true;

      description = "steamlibrary storage";

      what = "/dev/disk/by-label/SteamLibrary";
      where = "/var/mnt/SteamLibrary";
      options = "noatime";
      type = "btrfs";

      wantedBy = [ "multi-user.target" ];
    }
  ];

  virtualisation.podman.enable = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
  virtualisation.podman.extraPackages = [ pkgs.cni-plugin-flannel ];

  systemd.services.linger = {
    enable = true;

    requires = [ "local-fs.target" ];
    after = [ "local-fs.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        /run/current-system/sw/bin/loginctl enable-linger juuso
      '';
    };

    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.unmodeset = {
    enable = true;

    after = [ "umount.target" ];
    before = [ "kexec.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        /run/current-system/sw/bin/modprobe -r amdgpu nvidia_drm nouveau
      '';
    };

    wantedBy = [ "kexec.target" ];
  };

  systemd.services.ispyagentdvr = {
    path = [ "/run/wrappers" ];
    enable = true;

    description = "ispyagentdvr";
    requires = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      User = "juuso";
      Group = "juuso";
      Type = "simple";
    };

    script = ''${pkgs.podman}/bin/podman \
      --storage-opt "overlay.mount_program=${pkgs.fuse-overlayfs}/bin/fuse-overlayfs" run \
      --replace \
      --rm \
      --rmi \
      --name ispyagentdvr \
      --network=host \
      -p 8090:8090 \
      -p 3478:3478/udp \
      -p 50000-50010:50000-50010/udp \
      -v /var/mnt/bakhal/ispyagentdvr/config:/agent/Media/XML:Z \
      -v /var/mnt/bakhal/ispyagentdvr/media:/agent/Media/WebServerRoot/Media:Z \
      -v /var/mnt/bakhal/ispyagentdvr/archive:/agent/Media/WebServerRoot/Archive:Z \
      -v /var/mnt/bakhal/ispyagentdvr/commands:/agent/Commands:Z \
      docker.io/doitandbedone/ispyagentdvr
  '';

    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.netbootxyz = {
    path = [ "/run/wrappers" ];
    enable = true;

    description = "netbootxyz";
    requires = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      User = "juuso";
      Group = "juuso";
      Type = "simple";
    };

    preStart = ''
      ${pkgs.podman}/bin/podman network create netboot || true
    '';
    script = ''${pkgs.podman}/bin/podman \
      --storage-opt "overlay.mount_program=${pkgs.fuse-overlayfs}/bin/fuse-overlayfs" run \
      --replace \
      --rm \
      --rmi \
      --net=netboot \
      --name netbootxyz \
      -v /var/mnt/bakhal/netbootxyz/config:/config:z \
      -v /var/mnt/bakhal/netbootxyz/assets/public:/assets:z \
      ghcr.io/netbootxyz/netbootxyz
    '';

    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.synapse = {
    path = [ "/run/wrappers" ];
    enable = false;

    description = "Matrix homeserver";
    requires = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      User = "juuso";
      Group = "juuso";
      Type = "simple";
    };

    script = ''${pkgs.podman}/bin/podman \
      --storage-opt "overlay.mount_program=${pkgs.fuse-overlayfs}/bin/fuse-overlayfs" run \
      --replace \
      --rm \
      --rmi \
      --net=host \
      --name matrix \
      -v /var/mnt/bakhal/matrix/config:/data:z \
      -v /var/mnt/bakhal/matrix/acme:/acme:z \
      docker.io/matrixdotorg/synapse:latest
    '';

    wantedBy = [ "multi-user.target" ];
  };

  fileSystems."/export/nfs" = {
    device = "/var/mnt/bakhal/nfs";
    options = [ "bind" ];
  };
  services.nfs.server = {
    enable = true;
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';
    exports = ''
      /export         *.ponkila.periferia(rw,fsid=0,no_subtree_check)
      /export/nfs     *.ponkila.periferia(rw,nohide,insecure,no_subtree_check)
    '';
  };

  system.stateVersion = "23.05";
}
