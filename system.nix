{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
  ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/alistair/.config/sops/age/keys.txt";
  sops.secrets.k3s_cluster_secret = {};


  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users = {
    users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDvI8WT1wVlTtqheO4pS0zOInO9Da4V3BGeTOlTviCJx"];
    users.root.initialHashedPassword = "";
  };
  services.getty.autologinUser = "root";

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes";
    trusted-users = ["root" "@wheel"];
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.logind.lidSwitch = "ignore";

  services.k3s = {
    enable = true;
    role = "server";
    token = config.sops.secrets.k3s_cluster_secret.path;
    clusterInit = true;
  };
}
