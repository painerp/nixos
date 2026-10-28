{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.server.adguardhome;
  config-dir = config.lib.server.mkConfigDir "adguardhome";
  tailnet = import ../tailnet.nix;
  domain = config.server.base-domain;
  gateway = lib.concatStringsSep "." (
    lib.take 3 (lib.splitString "." cfg.traefik-network-ip) ++ [ "1" ]
  );

  local = name: "${name}.local.${domain}";
  cname = host: names: lib.genAttrs names (_: local host);
  rewrites =
    lib.mapAttrs' (host: s: lib.nameValuePair (local host) s.ip) tailnet.servers
    // cname "nixarr" (
      map local [
        "bazarr"
        "gluetun"
        "prdl"
        "prowlarr"
        "radarr"
        "sabnzbd"
        "sonarr"
        "stash"
        "t-arr"
      ]
    )
    // cname "nixcit" (
      map local [
        "adguardhome"
        "attic"
        "auth"
        "git"
        "home-assistant"
        "paperless"
        "peanut"
        "proxmox"
        "proxmox-backup"
        "sync"
        "t-cit"
        "truenas"
      ]
    )
    // cname "nixgam" [ (local "t-gam") ]
    // cname "nixgra" (
      map local [
        "immich"
        "jellyfin"
        "nextcloudaio"
        "t-gra"
        "tdarr"
      ]
    )
    // cname "nixinf" (
      map local [
        "agentmemory"
        "agentmemory-api"
        "dashboard"
        "pma.unknown"
        "t-inf"
        "track"
        "unknown"
      ]
    )
    // cname "nixlog" (
      map local [
        "alertmanager"
        "grafana"
        "metrics"
        "prometheus"
        "t-log"
      ]
    )
    // cname "nixfpi" (
      map (name: "${name}.f.${domain}") [
        "adguardhome"
        "atvloadly"
        "traefik"
        "yt2atv"
      ]
    )
    // {
      ${domain} = inputs.nixos-private.common.public-ip;
      "nc.${domain}" = domain;
      "jf.${domain}" = domain;
      "example.org" = "127.0.0.1";
    };

  filters = {
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt" = "AdGuard DNS filter";
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt" = "AdAway Default Blocklist";
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt" =
      "uBlock₀ filters – Badware risks";
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt" =
      "AdGuard DNS Popup Hosts filter";
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_51.txt" = "HaGeZi's Pro++ Blocklist";
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt" =
      "Phishing URL Blocklist (PhishTank and OpenPhish)";
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt" = "Steven Black's List";
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt" =
      "The Big List of Hacked Malware Web Sites";
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_23.txt" =
      "WindowsSpyBlocker - Hosts spy rules";
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_55.txt" =
      "HaGeZi's Badware Hoster Blocklist";
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt" =
      "HaGeZi's Threat Intelligence Feeds";
    "https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/DomainSquatting/DE/Sparkasse/Hessen1" =
      "RPiList - Domain Squatting";
    "https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/DomainSquatting/DE/Sparkasse/Hessen2" =
      "RPiList - Domain Squatting";
    "https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/DomainSquatting1" =
      "RPiList - Domain Squatting";
    "https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/DomainSquatting2" =
      "RPiList - Domain Squatting";
    "https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/notserious" =
      "RPiList - Domain Squatting";
    "https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/Phishing-Angriffe" =
      "RPiList - Phishing";
    "https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/spam.mails" =
      "RPiList - Spam";
    "https://raw.github.com/notracking/hosts-blocklists/master/hostnames.txt" = "Tracking";
    "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt" =
      "Perflyst - SmartTV Tracking";
    "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt" =
      "Perflyst - Android Tracking";
    "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/AmazonFireTV.txt" =
      "Perflyst - FireTV Tracking";
    "https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/Win10Telemetry" =
      "RPiList - Win10 Tracking";
    "https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/easylist" =
      "RPiList - Tracking";
    "https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/malware" =
      "RPiList - Malware";
    "https://v.firebog.net/hosts/Easyprivacy.txt" = "Fireborg - Ads";
    "https://v.firebog.net/hosts/Prigent-Ads.txt" = "Fireborg - Ads";
    "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt" = "anudeepND - Ads";
    "https://adaway.org/hosts.txt" = "Adaway - Ads";
    "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt" = "Disconnect - Ads";
    "https://raw.githubusercontent.com/notracking/hosts-blocklists/master/adblock/adblock.txt" =
      "NoTracking - Ads";
    "https://raw.githubusercontent.com/AdguardTeam/cname-trackers/master/data/combined_disguised_trackers.txt" =
      "ADGuard - Tracking";
    "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt" =
      "Crazy-Max - Windows Tracking";
    "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-blocklist.txt" =
      "Quidsup - Tracking";
  };

  tags = {
    artemis = [
      "device_laptop"
      "os_linux"
      "user_regular"
    ];
    dionysus = [
      "device_pc"
      "os_linux"
      "user_admin"
    ];
    pixel-9 = [
      "device_phone"
      "os_android"
      "user_admin"
    ];
  };

  settings = (pkgs.formats.yaml { }).generate "AdGuardHome.yaml" {
    http.address = "${if cfg.expose then "0.0.0.0" else gateway}:3000";
    dns = {
      # loopback for the local zone upstream
      bind_hosts =
        if cfg.expose then
          [ "0.0.0.0" ]
        else
          [
            config.server.tailscale-ip
            "127.0.0.1"
          ];
      # local zone goes back through the rewrites, so musl AAAA lookups on cname rewrites don't NXDOMAIN
      upstream_dns = [
        "[/local.${domain}/]127.0.0.1:53"
        "https://dns.quad9.net/dns-query"
      ];
      bootstrap_dns = [
        "9.9.9.9"
        "149.112.112.112"
        "2620:fe::fe"
        "2620:fe::9"
      ];
      cache_optimistic = true;
      use_private_ptr_resolvers = false;
    };
    filtering = {
      blocking_mode = "refused";
      rewrites = lib.mapAttrsToList (domain: answer: {
        inherit domain answer;
        enabled = true;
      }) rewrites;
    };
    filters = lib.mapAttrsToList (url: name: {
      inherit url name;
      enabled = true;
      # adguard caches each list as <id>.txt
      id = lib.fromHexString (builtins.substring 0 7 (builtins.hashString "sha256" url));
    }) filters;
    user_rules = [
      "# default block and whitelist"
      "||${domain}^"
    ]
    ++ map (sub: "@@|${sub}.${domain}^") [
      "ah"
      "auth"
      "jf"
      "ga"
      "gaw"
      "got"
      "mc"
      "nc"
      "pa"
      "sf"
      "st"
      "t"
    ]
    ++ inputs.nixos-private.common.adguardhome.user-rules;
    clients.persistent = lib.mapAttrsToList (name: ip: {
      inherit name;
      ids = [ ip ];
      tags =
        tags.${name} or [
          "device_other"
          "os_linux"
          "user_regular"
        ];
      use_global_settings = true;
      use_global_blocked_services = true;
    }) (tailnet.hosts // tailnet.clients);
  };
in
{
  options.server.adguardhome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    version = lib.mkOption { type = lib.types.str; };
    expose = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    traefik-network-ip = lib.mkOption {
      type = lib.types.str;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ah" else "adguardhome";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    dot = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    # host network, reached through the proxy network's gateway
    server.traefik.dynamic = lib.mkIf config.server.traefik.enable (
      config.lib.server.mkTraefikRoute {
        name = "adguardhome";
        inherit (cfg) subdomain;
        url = "http://${gateway}:3000";
        middlewares = lib.optional cfg.auth "authentik@docker";
      }
    );

    systemd.services.arion-adguardhome = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      # merged over adguard's own file so users and unmanaged settings stay, fresh installs run the setup wizard first
      preStart = ''
        if [ -f ${config-dir}/conf/AdGuardHome.yaml ]; then
          ${lib.getExe pkgs.yq-go} -i '. *= load("${settings}")' ${config-dir}/conf/AdGuardHome.yaml
        fi
      '';
    };

    virtualisation.arion.projects.adguardhome.settings = {
      project.name = "adguardhome";

      services.adguardhome.service = {
        image = "docker.io/adguard/adguardhome:${cfg.version}";
        container_name = "adguardhome";
        network_mode = "host";
        volumes = [
          "${config-dir}/work:/opt/adguardhome/work"
          "${config-dir}/conf:/opt/adguardhome/conf"
        ];
        environment = {
          TZ = config.time.timeZone;
        };
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };

    networking.firewall = {
      allowedTCPPorts = lib.mkIf (cfg.expose) ([ 53 ] ++ (if (cfg.dot) then [ 853 ] else [ ]));
      allowedUDPPorts = lib.mkIf (cfg.expose) [ 53 ];
      extraCommands = ''
        iptables -I nixos-fw -s ${cfg.traefik-network-ip}/16 -p tcp --dport 3000 -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -D nixos-fw -s ${cfg.traefik-network-ip}/16 -p tcp --dport 3000 -j nixos-fw-accept 2>/dev/null || true
      '';
    };
  };
}
