# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ kakoune lsof pstree tree ];
}
