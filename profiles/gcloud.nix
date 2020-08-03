{ lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/google-compute-image.nix"
  ];

  networking.firewall.enable = lib.mkForce true;
  services.journaldriver.enable = true;
}
