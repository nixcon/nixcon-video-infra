# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ lib, pkgs, config, ... }:

let
  inherit (lib) concatMapStrings mkEnableOption mkIf mkOption;
  inherit (lib.types) listOf port str;

  cfg = config.nixcon.rtmp-relay;
in

{
  options = {
    nixcon.rtmp-relay = {
      enable = mkEnableOption "NixCon RTMP push server";

      port = mkOption {
        type = port;
        default = 1935;
        description = "Source RTMP port";
      };

      recipients = mkOption {
        type = listOf str;
        example = [ "rtmp://example.com/foo/bar" ];
        description = "RTMP URLs to push to";
      };
    };
  };

  config = mkIf cfg.enable {
    # TODO: only allow RTMP traffic from trusted host.
    networking.firewall.allowedTCPPorts = [ cfg.port ];
    networking.firewall.allowedUDPPorts = [ cfg.port ];

    services.nginx.enable = true;

    # FIXME: it would be nice if there was a services.nginx.modules
    # option so these could compose.
    services.nginx.package = with pkgs;
      nginx.override { modules = with nginxModules; [ rtmp ]; };

    services.nginx.appendConfig = ''
      rtmp {
        server {
          listen ${toString cfg.port};

          application relay {
            live on;

            ${concatMapStrings (url: ''
              push ${url} live=1;
            '') cfg.recipients}
          }
        }
      }
    '';
  };
}
