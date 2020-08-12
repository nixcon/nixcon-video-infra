# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ ... }:

{
  imports = [
    ../profiles/acme.nix
    ../profiles/shell.nix
    ../profiles/ssh.nix
    ../profiles/users.nix
  ];

  # Please don't actually set anything in this file.  Let's keep stuff
  # in individual profiles with names and stuff.
}
