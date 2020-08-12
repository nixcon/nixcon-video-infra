# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ ... }:

{
  imports = [
    ../modules/dash.nix
    ../profiles/base.nix
  ];

  boot.isContainer = true;
  networking.useDHCP = false;
  networking.hostName = "testcon";
  networking.domain = "puck.moe";

  # TOOD: set up security@nixcon.net; have that forward to everyone on
  # the team, and then set this globally in acme.nix.
  security.acme.email = "hi@alyssa.is";

  environment.etc."resolv.conf".text = ''
    nameserver 1.1.1.1
  '';
  
  nixcon.dash.enable = true;
}
