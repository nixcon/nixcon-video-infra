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

    systemd.services.ffmpeg = {
      serviceConfig.ExecStart =
        "${pkgs.ffmpeg}/bin/ffmpeg -listen 1 -i rtmp://0.0.0.0:1935/src/main" +
        " -f flv -c:v libx264 -preset fast -s 854x480 rtmp://localhost:1936/dash/main_480p" +
        " -f flv -c:v libx264 -preset fast -s 1200x720 rtmp://localhost:1936/dash/main_720p" +
        " -f flv -c:v libx264 -preset fast -s 1920x1080 rtmp://localhost:1936/dash/main_1080p";
      serviceConfig.Restart = "always";
    };

    services.nginx.appendConfig = ''
      rtmp {
        server {
          listen 1936;

          application dash {
            live on;
            dash on;
            dash_nested on;
            dash_path /run/nginx/dash;
            dash_variant _480p bandwidth="409920" width="854" height="480";
            dash_variant _720p bandwidth="921600" width="1200" height="720";
            dash_variant _1080p bandwidth="2073600" width="1920" height="1080" max;
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
