{
  imports = [ ../../hardware/amd-5800x3d.nix ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/5A27-5DD4";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/b277bef3-cb17-4996-95ca-529208ad2738";
    fsType = "ext4";
  };

  fileSystems."/media/10tb" = {
    device = "/dev/disk/by-uuid/7812afa2-3544-4b10-9e54-c06999c8110a";
    fsType = "btrfs";
  };

  boot.initrd.luks.devices = {
    "luks-c7261900-049b-433c-8c8b-d96d9a68a9d6".device =
      "/dev/disk/by-uuid/c7261900-049b-433c-8c8b-d96d9a68a9d6";
    "luks-8089a368-5043-4915-a251-08688916a613".device =
      "/dev/disk/by-uuid/8089a368-5043-4915-a251-08688916a613";
  };

  modules.amd.enable = true;
}
