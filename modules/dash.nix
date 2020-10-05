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

    systemd.services.ffmpeg = {
      script = ''
        rm -rf /run/nginx/dash
        mkdir -p /run/nginx/dash

        ${pkgs.ffmpeg}/bin/ffmpeg -listen 1 -i rtmp://0.0.0.0:1935/src/main \
          -c:a aac \
          -c:v:0 libx264 -map v:0 -b:v:0 800k -s:0 854x480 -aspect:0 16:9 -preset:0 fast \
          -c:v:1 libx264 -map v:0 -b:v:1 1400k -s:1 1280x720 -aspect:1 16:9 -preset:1 fast \
          -c:v:2 copy -map v:0 -aspect:2 16:9 \
          -map 0:a \
          -f dash \
              -init_seg_name 'init$RepresentationID$.$ext$' \
              -media_seg_name 'chunk$RepresentationID$-$Number%05d$.$ext$' \
              -use_template 1 -use_timeline 1 \
              -seg_duration 5 -window_size 20 -remove_at_exit 1 \
              -hls_playlist 1 \
              -streaming 1 \
              -adaptation_sets "id=0,streams=v id=1,streams=a" \
              /run/nginx/dash/main.mpd
      '';
      serviceConfig.Restart = "always";
    };

    services.nginx.virtualHosts.${virtualHost} = {
      enableACME = true;
      addSSL = true;

      locations."~ ^/dash/.*\.m4s$" = {
        root = "/run/nginx";
        extraConfig = ''
          add_header Access-Control-Allow-Origin *;
        '';
      };

      locations."~ ^/dash/.*\.(mpd|m3u8)$" = {
        root = "/run/nginx";
        extraConfig = ''
          add_header Access-Control-Allow-Origin *;
          add_header Cache-Control no-cache;
        '';
      };
    };
  };
}
