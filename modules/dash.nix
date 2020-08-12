# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ lib, config, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) port nullOr str;

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

      rtmpPort = mkOption {
        type = port;
        default = 1935;
        description = ''
          Port to listen for incoming RTMP on.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # TODO: only allow RTMP traffic from trusted host.
    networking.firewall.allowedTCPPorts = [ cfg.rtmpPort 80 443 ];
    networking.firewall.allowedUDPPorts = [ cfg.rtmpPort ];

    services.nginx.enable = true;

    # FIXME: it would be nice if there was a services.nginx.modules
    # option so these could compose.
    services.nginx.package = with pkgs;
      nginx.override { modules = with nginxModules; [ rtmp ]; };

    services.nginx.appendConfig = ''
      rtmp {
        server {
          listen [::]:${toString cfg.rtmpPort};

          application dash {
            live on;
            dash on;
            dash_path /run/dash;
          }
        }
      }
    '';
    services.nginx.virtualHosts.${virtualHost} = {
      enableACME = true;
      forceSSL = true;

      locations."/dash" = {
        root = "/run";
        extraConfig = ''
          add_header Cache-Control no-cache;
        '';
      };
    };
  };
}
