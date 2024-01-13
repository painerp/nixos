{
  tailscale-api-key = ./tailscale-api-key.age;

  # containers
  teamspeak-env = ./containers/teamspeak.env.age;
  traefik-env = ./containers/traefik.env.age;
  watchtower-env = ./containers/watchtower.env.age;
  authentik-env = ./containers/authentik.env.age;
  authentik-pg-env = ./containers/authentik-pg.env.age;
  bachelor-env = ./containers/bachelor.env.age;
  bachelor-pg-env = ./containers/bachelor-pg.env.age;
  nuxt-pages-env = ./containers/nuxt-pages.env.age;
  nuxt-pages-mysql-env = ./containers/nuxt-pages-mysql.env.age;
  nuxt-pages-pma-env = ./containers/nuxt-pages-pma.env.age;
  nuxt-pages-g2g-env = ./containers/nuxt-pages-g2g.env.age;

  # variants
  bpi-user-pw = ./bpi/user-pw.age;
	bpi-wifi = ./bpi/wifi.age;
  jpi-user-pw = ./jpi/user-pw.age;
	jpi-wifi = ./jpi/wifi.age;
  ext-user-pw = ./ext/user-pw.age;
  ext-root-pw = ./ext/root-pw.age;
}