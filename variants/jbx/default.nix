{
  config,
  secrets,
  inputs,
  ...
}:

{
  imports = [ ./hardware.nix ];

  age.secrets.wifi.file = secrets.jbx-wifi;

  networking.wireless = {
    enable = true;
    secretsFile = config.age.secrets.wifi.path;
    networks = {
      "${inputs.nixos-private.common.wifi.ssid}".pskRaw = "ext:psk_fu";
      "${inputs.nixos-private.hosts.jbx.wifi.ssid}".pskRaw = "ext:psk_ju";
    };
  };

  modules = {
    arion.enable = true;
    kodi.enable = true;
  };

  server = {
    subdomain = "ju";
    adguardhome = {
      enable = true;
      version = "v0.107.79";
      expose = true;
    };
    traefik = {
      enable = true;
      expose = true;
      wildcard = true;
    };
    monitoring.alloy.enable = true;
    watchtower = {
      enable = true;
      schedule = "0 0 3 * * *";
    };
  };
}
