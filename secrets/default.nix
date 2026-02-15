{
  # containers
  traefik-env = ./containers/traefik.env.age;
  watchtower-env = ./containers/watchtower.env.age;

  pkgs-upload-file = ./pkgs/upload-file.age;

  extras-smtp = ./extras/smtp.age;

  # variants
  bpi-wifi = ./bpi/wifi.age;

  jpi-wifi = ./jpi/wifi.age;

  jbx-wifi = ./jbx/wifi.age;

  ext-authentik-env = ./ext/authentik.env.age;
  ext-authentik-pg-env = ./ext/authentik-pg.env.age;
  ext-bachelor-env = ./ext/bachelor.env.age;
  ext-bachelor-pg-env = ./ext/bachelor-pg.env.age;
  ext-nuxt-pages-env = ./ext/nuxt-pages.env.age;
  ext-nuxt-pages-mysql-env = ./ext/nuxt-pages-mysql.env.age;
  ext-nuxt-pages-pma-env = ./ext/nuxt-pages-pma.env.age;
  ext-nuxt-pages-g2g-env = ./ext/nuxt-pages-g2g.env.age;
  ext-open-webui-env = ./ext/open-webui.env.age;
  ext-teamspeak-env = ./ext/teamspeak.env.age;

  inf-authentik-proxy-env = ./inf/authentik-proxy.env.age;
  inf-jellystat-env = ./inf/jellystat.env.age;
  inf-jellystat-pg-env = ./inf/jellystat-pg.env.age;
  inf-linkwarden-env = ./inf/linkwarden.env.age;
  inf-linkwarden-pg-env = ./inf/linkwarden-pg.env.age;
  inf-unknown-env = ./inf/unknown.env.age;
  inf-unknown-mysql-env = ./inf/unknown-mysql.env.age;
  inf-unknown-pma-env = ./inf/unknown-pma.env.age;
  inf-dawarich-env = ./inf/dawarich.env.age;
  inf-dawarich-pg-env = ./inf/dawarich-pg.env.age;

  gra-authentik-proxy-env = ./gra/authentik-proxy.env.age;
  gra-immich-env = ./gra/immich.env.age;
  gra-immich-pg-env = ./gra/immich-pg.env.age;
  gra-jellyfin-exporter-env = ./gra/jellyfin-exporter.env.age;

  cit-git-pw = ./cit/git-pw.age;
  cit-adguardhome-sync-env = ./cit/adguardhome-sync.env.age;
  cit-attic-env = ./cit/attic.env.age;
  cit-authentik-env = ./cit/authentik.env.age;
  cit-authentik-pg-env = ./cit/authentik-pg.env.age;
  cit-gluetun-env = ./cit/gluetun.env.age;

  gam-palworld-env = ./gam/palworld.env.age;
  gam-minecraft-env = ./gam/minecraft.env.age;

  arr-authentik-proxy-env = ./arr/authentik-proxy.env.age;
  arr-gluetun-env = ./arr/gluetun.env.age;
  arr-prdl-env = ./arr/prdl.env.age;

  run-act-runner-env = ./run/act-runner.env.age;
  run-renovate-env = ./run/renovate.env.age;

  log-authentik-proxy-env = ./log/authentik-proxy.env.age;
  log-grafana-env = ./log/grafana.env.age;
  log-pve-exporter-env = ./log/pve-exporter.env.age;

  dionysus-dionysus-pw = ./dionysus/dionysus-pw.age;

  kronos-kronos-pw = ./kronos/kronos-pw.age;

  artemis-artemis-pw = ./artemis/artemis-pw.age;

  demeter-demeter-pw = ./demeter/demeter-pw.age;
}
