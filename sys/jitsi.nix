# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2020 Puck Meerburg <puck@puck.moe>
# SPDX-FileCopyrightText: 2020 edef <edef@edef.eu>
# SPDX-License-Identifier: MIT

{ ... }:

{
  imports = [
    ../modules/jitsi.nix
    ../profiles/base.nix
    ../profiles/gcloud.nix
  ];

  networking.hostName = "jitsi";
  networking.domain = "nixcon.net";

  # TOOD: set up security@nixcon.net; have that forward to everyone on
  # the team, and then set this globally in acme.nix.
  security.acme.email = "edef+nixcon@mutable.io";

  nixcon.jitsi.enable = true;
  nixcon.jitsi.videobridge.localAddress = "10.164.0.2";
}
