{
  secrets,
  ...
}:

let
  flake = "log";
  tailscale-ip = "100.73.203.96";
in
{
  imports = [ ./secrets ];

  networking.hostName = "nix${flake}";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/264b716c-0b9a-4e6c-b5e0-b72df598628e";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/590f1702-4605-4746-b6c4-95e07d6f8748"; } ];

  # system
  system = {
    inherit flake;
  };
  modules = {
    arion.enable = true;
  };

  # services
  server = {
    base-domain = "redacted";
    subdomain = "local";
    inherit tailscale-ip;
    authentik = {
      enable = true;
      proxy = true;
      env-file = secrets.log-authentik-proxy-env;
    };
    monitoring = {
      grafana = {
        enable = true;
        auth = false;
        env-file = secrets.log-grafana-env;
      };
      prometheus.enable = true;
      loki = {
        enable = true;
        internal = true;
      };
      node-exporter = {
        enable = true;
        internal = false;
      };
      pve-exporter = {
        enable = true;
        internal = false;
        env-file = secrets.log-pve-exporter-env;
      };
      promtail.enable = true;
      alertmanager.enable = true;
    };
    traefik = {
      enable = true;
      subdomain = "t-log";
    };
    watchtower.enable = true;
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
