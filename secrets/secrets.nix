let
  nix-master = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINeMjHcHigAw7K5OAemN4vu3vFEwKfHZ5HCVXfpSmKbk";
  users = [ nix-master ];

  jpi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGPwO0rR4DGyCTUTBQ8eZD57Sps/AeIYTooSFKollMAV";
  bpi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsEvJHm2Nyaps1z7Pk7tUAqNd6HZLhGeV4P8JVPbkla";
  ext = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAK9i6Ywzx4IFy5I7N4/OQJfd36cShHtWa9N+7tkEn3I";
  log = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINeMjHcHigAw7K5OAemN4vu3vFEwKfHZ5HCVXfpSmKbk";
  run = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICWdp6FGFKF8IlQAOf7U4gUVgFuUbSyXxjIDCcNd0Ffa";
  inf = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINeMjHcHigAw7K5OAemN4vu3vFEwKfHZ5HCVXfpSmKbk";
  gra = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINeMjHcHigAw7K5OAemN4vu3vFEwKfHZ5HCVXfpSmKbk";
  cit = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINeMjHcHigAw7K5OAemN4vu3vFEwKfHZ5HCVXfpSmKbk";
  arr = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINeMjHcHigAw7K5OAemN4vu3vFEwKfHZ5HCVXfpSmKbk";
  systems = [ jpi bpi ext log run inf cit arr ];
in
{
  # containers
  "containers/traefik.env.age".publicKeys = users ++ systems;
  "containers/watchtower.env.age".publicKeys = users ++ systems;

  "jpi/wifi.age".publicKeys = users ++ [ jpi ];

  "bpi/wifi.age".publicKeys = users ++ [ bpi ];

  "ext/authentik.env.age".publicKeys = users ++ [ ext ];
  "ext/authentik-pg.env.age".publicKeys = users ++ [ ext ];
  "ext/bachelor.env.age".publicKeys = users ++ [ ext ];
  "ext/bachelor-pg.env.age".publicKeys = users ++ [ ext ];
  "ext/nuxt-pages.env.age".publicKeys = users ++ [ ext ];
  "ext/nuxt-pages-pma.env.age".publicKeys = users ++ [ ext ];
  "ext/nuxt-pages-mysql.env.age".publicKeys = users ++ [ ext ];
  "ext/nuxt-pages-g2g.env.age".publicKeys = users ++ [ ext ];
  "ext/teamspeak.env.age".publicKeys = users ++ [ ext ];

  "inf/authentik-proxy.env.age".publicKeys = users ++ [ inf ];
  "inf/jellystat.env.age".publicKeys = users ++ [ inf ];
  "inf/jellystat-pg.env.age".publicKeys = users ++ [ inf ];

  "cit/git-pw.age".publicKeys = users ++ [ cit ];
  "cit/authentik.env.age".publicKeys = users ++ [ cit ];
  "cit/authentik-pg.env.age".publicKeys = users ++ [ cit ];

  "gra/authentik-proxy.env.age".publicKeys = users ++ [ gra ];

  "arr/authentik-proxy.env.age".publicKeys = users ++ [ arr ];
  "arr/gluetun.env.age".publicKeys = users ++ [ arr ];
  "arr/prdl.env.age".publicKeys = users ++ [ arr ];

  "run/act-runner.env.age".publicKeys = users ++ [ run ];

  "log/authentik-proxy.env.age".publicKeys = users ++ [ log ];
  "log/grafana.env.age".publicKeys = users ++ [ log ];
}
