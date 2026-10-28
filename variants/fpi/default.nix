{
  secrets,
  inputs,
  ...
}:

{
  imports = [ ./hardware.nix ];

  modules = {
    arion = {
      enable = true;
      registry-login = true;
    };
    tailscale.subnet-router = true;
  };

  server = {
    subdomain = "f";
    adguardhome = {
      enable = true;
      version = "v0.107.79";
      expose = true;
    };
    atvloadly.enable = true;
    yt2atv = {
      enable = true;
      image = inputs.nixos-private.hosts.fpi.yt2atv.image;
      env-file = secrets.fpi-yt2atv-env;
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
