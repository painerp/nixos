{
  imports = [ ../../hardware/int-vps.nix ];

  networking.interfaces.ens19.ipv4.addresses = [
    {
      address = "10.0.10.20";
      prefixLength = 24;
    }
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/84ccc144-81ac-471e-82e3-ca4ce6a5100e";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/2c3aafdb-cb5a-41bc-a2e6-99059466a03b"; } ];
}
