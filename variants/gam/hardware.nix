{
  imports = [ ../../hardware/int-vps.nix ];

  networking.interfaces.ens19.ipv4.addresses = [
    {
      address = "10.0.10.50";
      prefixLength = 24;
    }
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/51277ab7-6113-497f-b1c2-a4cc6ea5a663";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/c0811b51-5a31-42cd-a982-c7bc5fbb2b7e"; } ];
}
