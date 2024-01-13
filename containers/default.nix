{ lib, config, arion, agenix, ... }:

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

  imports = [ 
		./authentik.nix
		./bachelor.nix
		./gotify.nix
		./jellyfin-vue.nix
		./monitoring.nix
		./nuxt-pages.nix
		./pihole.nix
		./protonbridge.nix
		./teamspeak.nix
		./traefik.nix
		./uptime-kuma.nix
		./watchtower.nix
	];

  config = {
    lib.server.mkServiceSubdomain = subdomain: "${subdomain}.${config.server.domain}";
    lib.server.mkConfigDir = name: "${config.server.config-dir}/${name}";
  };
}