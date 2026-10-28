{
  imports = [ ../../hardware/vps.nix ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/27f84bd7-9372-4254-ac51-ad7b0f2acffb";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DCCB-DD8F";
    fsType = "vfat";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/4922412f-2a31-4239-8c30-ad2b0f0c94ca"; } ];
}
