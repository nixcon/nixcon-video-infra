# SPDX-FileCopyrightText: 2020 Puck Meerburg <puck@puck.moe>
# SPDX-License-Identifier: MIT

{ lib, config, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) port str;

  cfg = config.nixcon.jitsi.remote;

in

{
  options = {
    nixcon.jitsi.remote = {
      enable = mkEnableOption "NixCon Jitsi Bridge Cascading";
      bindAddress = mkOption {
        type = str;
        description = ''
          Address to bind to locally.
        '';
      };
      publicAddress = mkOption {
        type = str;
        description = ''
          The address to advertise for bridge cascading.
        '';
      };
      bindPort = mkOption {
        type = port;
        description = ''
          The port to bind to.
        '';
      };
      region = mkOption {
        type = str;
        description = ''
          The region of this Videobridge instance.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.bindPort ];
    networking.firewall.allowedUDPPorts = [ cfg.bindPort ];

    services.jitsi-videobridge = {
      enable = true;
      config.videobridge.octo = {
        inherit (cfg) region;
        enabled =  true;
        bind-address = cfg.bindAddress;
        public-address = cfg.publicAddress;
        bind-port = cfg.bindPort;
      };
    };
  };
}
