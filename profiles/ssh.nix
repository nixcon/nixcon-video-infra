# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ ... }:

{
  services.openssh.enable = true;
  programs.mosh.enable = true;
}
