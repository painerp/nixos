let
  nix-master =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINeMjHcHigAw7K5OAemN4vu3vFEwKfHZ5HCVXfpSmKbk";
  users = [ nix-master ];

  jpi =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGPwO0rR4DGyCTUTBQ8eZD57Sps/AeIYTooSFKollMAV";
  bpi =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsEvJHm2Nyaps1z7Pk7tUAqNd6HZLhGeV4P8JVPbkla";
  ext =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAK9i6Ywzx4IFy5I7N4/OQJfd36cShHtWa9N+7tkEn3I";
  log =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2TuNrV3HTsPpPg2f3ziB2Iug4rqOvvi078DsBe/5GP";
  run =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDukRN3AKfGtGhjagYmCu3U8rr0Mh/FywyJDA2GN8iPE";
  inf =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+uAHS+HxLB0UnSoi64GYFO4KE9ypNdiL0AR6+R5sKN";
  gra =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBDDnSDmPNDQemH321BQZSxBESYZRE6mzXEJCTtdxtJ";
  gam =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbkOe5w4Tj2hEkG2HdL4UqbwC7kVmS7Z4IsMgQvUcQD";
  cit =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9kVFMfWDbqbzfFaOnEHSlofWUKZAJUATkHN+nlUK/X";
  arr =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGF1rLbYjyiGRfdPHKxmuiTd650+Iy0VR2/qM5T06PAv";
  systems = [ jpi bpi ext log run inf gam cit gra arr ];
in {
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

  "gam/palworld.env.age".publicKeys = users ++ [ gam ];

  "arr/authentik-proxy.env.age".publicKeys = users ++ [ arr ];
  "arr/gluetun.env.age".publicKeys = users ++ [ arr ];
  "arr/prdl.env.age".publicKeys = users ++ [ arr ];

  "run/act-runner.env.age".publicKeys = users ++ [ run ];

  "log/authentik-proxy.env.age".publicKeys = users ++ [ log ];
  "log/grafana.env.age".publicKeys = users ++ [ log ];
  "log/pve-exporter.env.age".publicKeys = users ++ [ log ];
}
