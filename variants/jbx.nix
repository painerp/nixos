{
  config,
  secrets,
  inputs,
  ...
}:

let
  flake = "jbx";
  tailscale-ip = "100.103.104.35";
in
{
  age.secrets.wifi.file = secrets.jbx-wifi;

  # wlan
  networking = {
    hostName = "nix${flake}";
    wireless = {
      enable = true;
      secretsFile = config.age.secrets.wifi.path;
      networks = {
        "${inputs.nixos-private.common.wifi.ssid}".pskRaw = "ext:psk_fu";
        "${inputs.nixos-private.hosts."${flake}".wifi.ssid}".pskRaw = "ext:psk_ju";
      };
    };
  };

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
