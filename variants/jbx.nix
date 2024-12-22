{
  lib,
  config,
  secrets,
  ...
}:

let
  flake = "jbx";
  tailscale-ip = "100.103.104.35";
in
{
  imports = [
    ./secrets
    ./secrets/jbx.nix
  ];
  # secrets
  age.secrets.wifi.file = secrets.jbx-wifi;

  # wlan
  networking = {
    hostName = "nix${flake}";
    wireless.secretsFile = config.age.secrets.wifi.path;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/8dd1533d-36dd-4ebc-a528-0abb85e5b6c5";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8530-EC8C";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # system
  system = {
    inherit flake;
  };
  modules = {
    arion.enable = true;
    kodi.enable = true;
  };

  # services
  server = {
    base-domain = "redacted";
    subdomain = "ju";
    inherit tailscale-ip;
    adguardhome = {
      enable = true;
      expose = true;
    };
    traefik = {
      enable = true;
      expose = true;
      wildcard = true;
    };
    watchtower = {
      enable = true;
      schedule = "0 0 3 * * *";
    };
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
