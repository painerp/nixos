{ secrets, ... }:

{
  imports = [ ./hardware.nix ];

  modules = {
    arion = {
      enable = true;
      backend = "podman";
      registry-login = true;
    };
    attic-builder = {
      enable = true;
      max-memory-per-worker = 8192;
    };
  };

  server = {
    subdomain = "local";
    forgejo-runner = {
      enable = true;
      version = "13.2.0";
      config-file = secrets.run-forgejo-runner-config;
    };
    renovate = {
      enable = true;
      platform = "forgejo";
      ssh = true;
      timer = "1h";
      env-file = secrets.run-renovate-env;
    };
    monitoring.alloy.enable = true;
    watchtower = {
      enable = true;
      only-label = true;
      include-stopped = true;
    };
  };
}
