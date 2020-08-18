# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ ... }:

{
  imports = [
    ../modules/rtmp-push.nix
    ../profiles/base.nix
    ../profiles/gcloud.nix
  ];

  networking.hostName = "relay01";
  networking.domain = "nixcon.net";

  nixcon.rtmp-relay.enable = true;
  nixcon.rtmp-relay.recipients = [ "rtmp://dash01.nixcon.net/dash/main" ];
}
