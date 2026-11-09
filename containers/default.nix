{
  lib,
  config,
  pkgs,
  arion,
  agenix,
  ...
}:

let
  cfg = config.server;
in
{
  options.server = {
    base-domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain that all services will be deployed to";
      default = "localhost";
    };

    subdomain = lib.mkOption {
      type = lib.types.str;
      description = "The subdomain that all services will be deployed to";
      default = "";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain that all services will be deployed to";
      default = if cfg.subdomain == "" then cfg.base-domain else "${cfg.subdomain}.${cfg.base-domain}";
      readOnly = true;
    };

    tailscale-ip = lib.mkOption {
      type = lib.types.str;
      description = "The IP address of the Tailscale interface";
    };

    config-dir = lib.mkOption {
      type = lib.types.str;
      description = "The configuration directory";
      default = "/root/config";
    };

    short-subdomain = lib.mkOption {
      type = lib.types.bool;
      description = "Use shorter versions of subdomains for services";
      default = false;
    };
  };

  imports = map (n: ./${n}) (
    lib.attrNames (
      lib.filterAttrs (n: t: t == "regular" && n != "default.nix" && lib.hasSuffix ".nix" n) (
        builtins.readDir ./.
      )
    )
  );

  config = {
    lib.server.mkServiceSubdomain = subdomain: "${subdomain}.${config.server.domain}";
    lib.server.mkConfigDir = name: "${config.server.config-dir}/${name}";
    lib.server.boolToStr = b: if b then "true" else "false";
    lib.server.mkDbBackup =
      {
        type,
        container,
        dir,
      }:
      let
        dump =
          {
            mysql = ''MYSQL_PWD="''${MARIADB_ROOT_PASSWORD:-$MYSQL_ROOT_PASSWORD}" exec mariadb-dump -uroot --all-databases --single-transaction --routines --events'';
            postgres = ''exec pg_dumpall --clean --if-exists -U "$POSTGRES_USER"'';
            vaultwarden = "rm -f /data/db_*.sqlite3 && /vaultwarden backup >&2 && cat /data/db_*.sqlite3 && rm /data/db_*.sqlite3";
          }
          .${type};
        ext = if type == "vaultwarden" then "sqlite3.gz" else "sql.gz";
      in
      {
        startAt = "*-*-* 23:30:00";
        path = [
          pkgs.docker-client
          pkgs.gzip
        ];
        serviceConfig.Type = "oneshot";
        script = ''
          set -o pipefail
          mkdir -p ${dir}
          docker exec ${container} sh -c '${dump}' | gzip > ${dir}/.dump.tmp
          mv ${dir}/.dump.tmp "${dir}/$(date +%F).${ext}"
          find ${dir} -name '*.${ext}' -mtime +6 -delete
        '';
      };
  };
}
