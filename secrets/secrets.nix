let
  nix-master = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINeMjHcHigAw7K5OAemN4vu3vFEwKfHZ5HCVXfpSmKbk";
  users = [ nix-master ];

  jpi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGPwO0rR4DGyCTUTBQ8eZD57Sps/AeIYTooSFKollMAV";
  bpi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsEvJHm2Nyaps1z7Pk7tUAqNd6HZLhGeV4P8JVPbkla";
  ext = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAK9i6Ywzx4IFy5I7N4/OQJfd36cShHtWa9N+7tkEn3I";
  systems = [ jpi bpi ext ];
in
{
  # general
  "tailscale-api-key.age".publicKeys = users ++ systems;

  # containers
  "containers/traefik.env.age".publicKeys = users ++ systems;
  "containers/watchtower.env.age".publicKeys = users ++ systems;
  "containers/teamspeak.env.age".publicKeys = users ++ [ ext ];
  "containers/authentik.env.age".publicKeys = users ++ [ ext ];
  "containers/authentik-pg.env.age".publicKeys = users ++ [ ext ];
  "containers/bachelor.env.age".publicKeys = users ++ [ ext ];
  "containers/bachelor-pg.env.age".publicKeys = users ++ [ ext ];
  "containers/nuxt-pages.env.age".publicKeys = users ++ [ ext ];
  "containers/nuxt-pages-pma.env.age".publicKeys = users ++ [ ext ];
  "containers/nuxt-pages-mysql.env.age".publicKeys = users ++ [ ext ];
  "containers/nuxt-pages-g2g.env.age".publicKeys = users ++ [ ext ];

  "jpi/user-pw.age".publicKeys = users ++ [ jpi ];
  "jpi/wifi.age".publicKeys = users ++ [ jpi ];

  "bpi/user-pw.age".publicKeys = users ++ [ bpi ];
  "bpi/wifi.age".publicKeys = users ++ [ bpi ];

  "ext/user-pw.age".publicKeys = users ++ [ ext ];
  "ext/root-pw.age".publicKeys = users ++ [ ext ];
}
