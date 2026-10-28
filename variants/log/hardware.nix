{
  imports = [ ../../hardware/int-vps.nix ];

  networking.interfaces.ens19.ipv4.addresses = [
    {
      address = "10.0.10.100";
      prefixLength = 24;
    }
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/264b716c-0b9a-4e6c-b5e0-b72df598628e";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/590f1702-4605-4746-b6c4-95e07d6f8748"; } ];
}
