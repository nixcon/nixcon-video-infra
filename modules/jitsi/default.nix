# SPDX-FileCopyrightText: 2020 Puck Meerburg <puck@puck.moe>
# SPDX-License-Identifier: MIT

{ lib, config, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) attrsOf port nullOr str submodule;

  cfg = config.nixcon.jitsi;
  localHostname = "${config.networking.hostName}.${config.networking.domain}";

in

{
  options = {
    nixcon.jitsi = {
      enable = mkEnableOption "NixCon Jitsi setup";

      videobridge = {
        localAddress = mkOption {
          type = str;
          example = "10.164.0.2";
          description = ''
            The local IP of this machine, necessary for videobridge usage.
          '';
        };

        publicAddress = mkOption {
          type = str;
          example = "198.51.100.1";
          default = localHostname + ".";
          description = ''
            The external IP (or hostname) of this machine, used to connect to this videobridge.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 443 4433 5222 ];
    networking.firewall.allowedUDPPorts = [ 10000 ];

    services.jitsi-videobridge.nat = {
      inherit (cfg.videobridge) localAddress publicAddress;
    };

    services.jitsi-meet = {
      enable = true;
      jibri.enable = true;

      # Set the XMPP server location.
      hostName = localHostname;

      config = {
        # Default to 720p video
        resolution = 720;
        constraints.video = {
          height = {
            ideal = 720;
            max = 720;
            min = 180;
          };

          width = {
            ideal = 1280;
            max = 1280;
            min = 320;
          };
        };

        # use P2P for two-person chats, same settings as meet.jit.si
        p2p = {
          enabled = true;
          disableH264 = true;
          useStunTurn = true;
        };

        enableInsecureRoomNameWarning = false;
        enableLayerSuspension = true;
        prejoinPageEnabled = true;
        startBitrate = "800";

        # Enable some RTP extensions, equivalent to jitsi meet
        enableRemb = true;
        enableTcc = true;

        testing.octo.probability = 1;
        deploymentInfo.userRegion = "cloud";
      };
    };

    services.jicofo.config."org.jitsi.jicofo.BridgeSelector.BRIDGE_SELECTION_STRATEGY" = "RegionBasedBridgeSelectionStrategy";

    services.prosody = {
      extraModules = [ "muc_stats" ];
      extraPluginPaths = [ ./prosody-modules ];
    };
  };
}
