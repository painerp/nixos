{
  imports = [ ../../hardware/thinkcentre-m715q.nix ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8530-EC8C";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/8dd1533d-36dd-4ebc-a528-0abb85e5b6c5";
    fsType = "ext4";
  };
}
