{
  secrets,
  ...
}:

let
  flake = "run";
  tailscale-ip = "100.113.149.64";
in
{
  networking.hostName = "nix${flake}";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6b1b23b8-f684-4e29-8680-78e5214ae4b6";
    fsType = "ext4";
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/e5863ec2-52d0-4a56-a0e8-43c211e28e69";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/351ceb5f-c78d-4560-ad86-d78d646fd3a5"; } ];

  # system
  system = {
    inherit flake;
  };
  modules = {
    arion = {
      enable = true;
      backend = "podman";
    };
    attic-builder = {
      enable = true;
      max-memory-per-worker = 8192;
    };
  };

  # services
  server = {
    subdomain = "local";
    inherit tailscale-ip;
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
    monitoring.alloy = {
      enable = true;
      loki.address = "100.73.203.96";
      prometheus.address = "100.73.203.96";
    };
    watchtower = {
      enable = true;
      only-label = true;
      include-stopped = true;
    };
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
