{ secrets, pkgs, ... }:

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

  # podman > 5.8.4 breaks the forgejo runner's action copy: "statat ...: path escapes from parent"
  virtualisation.podman.package = pkgs.podman.overrideAttrs (_: rec {
    version = "5.8.4";
    src = pkgs.fetchFromGitHub {
      owner = "containers";
      repo = "podman";
      tag = "v${version}";
      hash = "sha256-zhEtMZVKiv1L72EMlwgz8sHpmvhejGp98oW63aPj+rQ=";
    };
  });

  server = {
    subdomain = "local";
    forgejo-runner = {
      enable = true;
      version = "13.2.1";
      config-file = secrets.run-forgejo-runner-yml;
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
