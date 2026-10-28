{
  imports = [ ../../hardware/int-vps.nix ];

  networking.interfaces.ens19.ipv4.addresses = [
    {
      address = "10.0.10.80";
      prefixLength = 24;
    }
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5f9a25d7-4fd8-48ab-a510-3c00bdfd3edf";
    fsType = "ext4";
  };

  fileSystems."/tmp/unprocessed" = {
    device = "/dev/disk/by-uuid/e98ab9e9-6add-4298-a78b-6bdb55cde4d5";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/fe045a17-5b72-45fc-8e9f-1b55989734d0"; } ];
}
