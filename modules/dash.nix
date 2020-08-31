# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ lib, config, pkgs, ... }:

let
  inherit (lib) concatStrings mapAttrsToList mkEnableOption mkIf mkOption;
  inherit (lib.types) attrsOf port nullOr str submodule;

  cfg = config.nixcon.dash;
  virtualHost = if cfg.virtualHost == null
                then "${config.networking.hostName}.${config.networking.domain}"
                else cfg.virtualHost;
in

{
  options = {
    nixcon.dash = {
      enable = mkEnableOption "NixCon DASH server";

      virtualHost = mkOption {
        type = nullOr str;
        default = null;
        example = "example.com";
        description = ''
          Nginx virtual host on which to serve DASH.  If not
          specified, defaults to the system FQDN.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # TODO: only allow RTMP traffic from trusted host.
    networking.firewall.allowedTCPPorts = [ 80 443 1935 ];
    networking.firewall.allowedUDPPorts = [ 1935 ];

    services.nginx.enable = true;

    # FIXME: it would be nice if there was a services.nginx.modules
    # option so these could compose.
    services.nginx.package = with pkgs;
      nginx.override { modules = with nginxModules; [ rtmp ]; };

    services.nginx.appendConfig = ''
      rtmp {
        server {
          listen 1935;

          application dash {
            live on;
            dash on;
            dash_path /run/nginx/dash;
          }
        }
      }
    '';

    services.nginx.virtualHosts.${virtualHost} = {
      enableACME = true;
      forceSSL = true;

      locations."/dash" = {
        root = "/run/nginx";
        extraConfig = ''
          add_header Access-Control-Allow-Origin *;
          add_header Cache-Control no-cache;
        '';
      };
    };
  };
}
