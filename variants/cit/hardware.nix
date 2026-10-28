{
  imports = [ ../../hardware/int-vps.nix ];

  networking.interfaces.ens19.ipv4.addresses = [
    {
      address = "10.0.10.10";
      prefixLength = 24;
    }
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1ca563af-ad9e-4629-8f43-4e8436dd6c6c";
    fsType = "ext4";
  };

  fileSystems."/mnt/attic" = {
    device = "/dev/disk/by-uuid/ce10438b-ca74-46b3-8c88-2f20199eb3f0";
    fsType = "ext4";
    options = [
      "defaults"
      "noatime"
    ];
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/ab983818-1f80-49a0-9beb-0e5329843b83"; } ];
}
