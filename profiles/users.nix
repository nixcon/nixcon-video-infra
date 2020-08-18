# SPDX-FileCopyrightText: 2020 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ lib, config, ... }:

{
  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;

  users.users.puck = {
    isNormalUser = true;
    description = "Puck Meerburg";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtxV2PBVLfhMLXBbmEE6x3FwmoiYILf3VbhPFZH3Wnqy7P5JM2g6aIXPMi5GyrL+FuG24Wiz7erl9MIB73eSCIcrEMFcDtch5R19kKtH7OMnC6LPgAxBpZycHmXWAmQ5dmkFH6Exr/+DvQ6OxJk+T7y4K6zhwunjfqlKiPsLL1WVyxuSaj1lnvzRmaPL99slfg5RcXg+sbIEhSVKOsKjbuS88RNPjfAOcGMhFsMHBHPLYoVOgPL263TokyDXlN7/50IbV8b+ul3Zr1f0ntjts9qgjWJGK5D5VAkX7jBkg2H2jM1JN5IbSgrTxFQx9cbzJg4JEFPCv1Oo1gHan8zbzKJrJPWnRv9Gt/UcvmhD2hijnK8FrC36S5/lmCHxDlwCtEfAjL1y7Cdp889AuvYbShNJA29I2iNt7i0p1VluqzjexxvquN7u/M/ftLDdzUzfCVFJzPgp3RDEiv+9yjpwrNcEzgLe2OwSonAt+papkorz3n8gWY5maSlvWntSQx/PahVsAVFN/+7tEUu5F0uKbD7xYKdBRUEFl+/h+AFEMCFuKVxyCrDncvlm9WzTOoCovCymADfJokBnjag1v+8XdS9xFQo/TVrL5T2/FLjVnY89k0rVPlxcf0kaNnshp8SWLTbYXj4zfMxC8UDSw7OrTKa0WOCUrVeEbehR0ezfSUAQ== puck"
    ];
  };

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
      [ "puck" "qyliss" ];
}
