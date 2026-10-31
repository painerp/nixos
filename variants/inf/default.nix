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
      backend = "podman";
      tailscale-dependent = true;
    };
    borg.enable = true;
    nfs.mounts."/mnt/unknown" = "unknown";
  };

  server = {
    subdomain = "local";
    agentmemory = {
      enable = true;
      version = "0.9.30";
      env-file = secrets.inf-agentmemory-env;
      provider.env-file = secrets.inf-agentmemory-provider-env;
    };
    authentik = {
      enable = true;
      proxy = true;
      version = "2026.8.5";
      env-file = secrets.inf-authentik-proxy-env;
    };
    dashboard.enable = true;
    unknown = {
      enable = true;
      image = inputs.nixos-private.hosts.inf.unknown.image;
      extras-dir = "/mnt/unknown";
      env-file = secrets.inf-unknown-env;
      mysql.env-file = secrets.inf-unknown-mysql-env;
      pma = {
        enable = true;
        subdomain = "pma";
        env-file = secrets.inf-unknown-pma-env;
      };
    };
    dawarich = {
      enable = true;
      version = "1.20.0";
      auth = false;
      env-file = secrets.inf-dawarich-env;
      postgres.env-file = secrets.inf-dawarich-pg-env;
    };
    monitoring.alloy.enable = true;
    traefik = {
      enable = true;
      subdomain = "t-inf";
      restrict-servers = true;
    };
    watchtower.enable = true;
  };
}
