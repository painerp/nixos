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
    act-runner = {
      enable = true;
      env-file = secrets.run-act-runner-env;
    };
    renovate = {
      enable = true;
      ssh = true;
      timer = "1h";
      env-file = secrets.run-renovate-env;
    };
    monitoring = {
      node-exporter.enable = true;
      cadvisor.enable = true;
      promtail = {
        enable = true;
        loki.address = "100.73.203.96";
      };
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
