# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ lib, config, ... }:

{
  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;

  users.users.qyliss = {
    isNormalUser = true;
    description = "Alyssa Ross";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDO11Pr7jKaRZ2It1yB312SKFN8mCV7aVYdry16LNwtnA6EDgFxyshG4Zmhl9asxQ9wa1lT3tdKB6ArA+VKxXMZB0zm15jYSLKpHQxMT7T3SqtTluJQpJD9zRtWeHbW/e1mtgn3tPYTHERB4HVGKIeGk97eOR2YOdXPHOIWhOXpogDtUlyt1bmWl0gyRHbWhViLeReHYhsu0KbZlo+ntN9aN7lPVkDfa7gUARv6IeGE5hAYHPRWmQ3VJCDaQnzsTtesLPFiNmV6Pq7qtWbHVNOG9XQLXJhD/305+yDZ2y/+KuBEQCroiWF8fPY/8gutfkZ0ZLjdGbXl38j5v+yRjreh+wjcN5MYWCWM18hMdutpoMd9D7PXaZz90V2vS+mRC81t3zXKrAy3Ke+LQBmlWSWxmKWdDoOTGOHjyPuCC/q+In7Q8hetB9/b9WUXTwEaaE3lUsa7y5JHAekNmdSoN3WD10nGYVUMvRRPGAlyqZTQdvxhn+6Pyu2piwIv/TMmC1CwiHr+fLbHxXQF745sOBQNmrdfiOzqDsKleybNB6i0AdDm5UZcYRcMLuxmryxN8O8qNUdMjMGoCeFcGwAIieqM+0xkPiByKr8ky2yV2lwOaZ4jrp/3j5GsGoQlvNKIPdCA/GQFad6vuqvhlbWcbdfiNpawrppLcJBsGB2NVjGbNQ=="
    ];
  };

  users.users.root.openssh.authorizedKeys.keys =
    lib.concatMap (u: config.users.users.${u}.openssh.authorizedKeys.keys)
      [ "qyliss" ];
}
