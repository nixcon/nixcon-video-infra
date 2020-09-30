# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2020 Puck Meerburg <puck@puck.moe>
# SPDX-FileCopyrightText: 2020 edef <edef@edef.eu>
# SPDX-License-Identifier: MIT

{ lib, ... }:

{
  imports = [
    ../modules/jitsi
    ../modules/jitsi/remote.nix
    ../modules/prometheus.nix
    ../profiles/base.nix
    ../profiles/gcloud.nix
  ];

  networking.hostName = "jitsi";
  networking.domain = "nixcon.net";

  networking.hosts = {
    "127.0.0.1" = [ "auth.jitsi.nixcon.net" ];
  };

  # TOOD: set up security@nixcon.net; have that forward to everyone on
  # the team, and then set this globally in acme.nix.
  security.acme.email = "edef+nixcon@mutable.io";

  nixcon.jitsi.enable = true;
  nixcon.jitsi.videobridge.localAddress = "10.164.0.2";

  nixcon.jitsi.remote = {
    enable = true;
    bindAddress = "10.164.0.2";
    publicAddress = "jitsi.nixcon.net.";
    bindPort = 4096;
    region = "cloud";
  };

  services.prometheus.enable = true;
  services.grafana = {
    enable = true;
    # TODO(edef): put this behind nginx
    addr = "0.0.0.0";
    # TODO(edef): set domain
    provision = {
      enable = true;
      datasources = lib.singleton {
        type = "prometheus";
        name = "Prometheus";
        url = "http://localhost:9090";
      };
    };
  };

  services.prometheus.exporters.node.enable = true;
}
