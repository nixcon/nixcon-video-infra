# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ ... }:

{
  imports = [
    ../modules/dash.nix
    ../profiles/base.nix
    ../profiles/gcloud.nix
  ];

  networking.hostName = "dash01";
  networking.domain = "nixcon.net";

  # TOOD: set up security@nixcon.net; have that forward to everyone on
  # the team, and then set this globally in acme.nix.
  security.acme.email = "hi@alyssa.is";

  nixcon.dash.enable = true;
}
