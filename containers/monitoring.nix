{ lib, config, ... }:

let
  cfg = config.server.monitoring;
in
{
  options.server.monitoring = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enabled) {
    systemd.services.arion-monitoring = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.monitoring.settings = {
      project.name = "monitoring";
      services.node-exporter.service = {
        image = "quay.io/prometheus/node-exporter:latest";
        container_name = "node-exporter";
        command = [ "--path.rootfs=/host" ];
        volumes = [ "/:/host:ro,rslave" ];
        restart = "unless-stopped";
      };

      services.cadvisor.service = {
        image = "gcr.io/cadvisor/cadvisor:latest";
        container_name = "cadvisor";
        command = [
          "--housekeeping_interval=10s"
          "--docker_only"
          "--store_container_labels=false"
        ];
        volumes = [
          "/:/rootfs:ro"
          "/var/run:/var/run:ro"
          "/sys:/sys:ro"
          "/var/lib/docker/:/var/lib/docker:ro"
          "/dev/disk/:/dev/disk:ro"
        ];
        devices = [ "/dev/kmsg" ];
        privileged = true;
        restart = "unless-stopped";
      };
    };
  };
}