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
    inputs.proxmox-nixos.nixosModules.proxmox-ve
  ];

  nixpkgs.overlays = [
    inputs.proxmox-nixos.overlays."x86_64-linux"
  ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/alistair/.config/sops/age/keys.txt";

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

    extra-substituters = ["https://cache.nixos.org/" "https://nix-community.cachix.org/" "https://cache.saumon.network/proxmox-nixos"];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "proxmox-nixos:D9RYSWpQQC/msZUWphOY2I5RLH5Dd6yQcaHIuug7dWM="
    ];
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
  };

  sops.secrets = {
    k3s_cluster_secret = {};
    "grafana/admin_password" = {};
  };

  services.k3s = {
    enable = true;
    role = "server";
    token = config.sops.secrets.k3s_cluster_secret.path;
    clusterInit = true;
  };

  services.grafana = {
    enable = true;
    settings = {
      security.admin_password = config.sops.secrets."grafana/admin_password".path;
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
    };
  };
}
