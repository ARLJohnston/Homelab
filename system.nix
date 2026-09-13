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
    experimental-features = [
      "nix-command"
      "flakes"
    ];
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
    "grafana/secret_key" = {};
  };

  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;

    tokenFile = config.sops.secrets.k3s_cluster_secret.path;

    extraFlags = [
      "--node-ip=192.168.8.141"
      "--advertise-address=192.168.8.141"
      "--disable=traefik"
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      security.admin_password = config.sops.secrets."grafana/admin_password".path;
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      security.secret_key = config.sops.secrets."grafana/secret_key".path;
    };
  };
  # Ollama Service Configuration & Networking Requirements
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda.override {
        # nvidia-smi --query-gpu=compute_cap
        cudaArches = [ "61" ];
    };
    host = "0.0.0.0";
    port = 11434;
  };

  systemd.services.ollama.environment = {OLLAMA_CONTEXT_LENGTH = "32768";};

  environment.systemPackages = with pkgs; [
    ollama-cuda
  ];
  hardware.nvidia-container-toolkit.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) ["cuda_cudart" "cuda_nvcc" "cuda_cccl" "libcublas" "cuda_nvrtc" "nvidia-x11" "nvidia-settings" "nvidia-kernel-modules"];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    open = false;
    modesetting.enable = true;

    nvidiaPersistenced = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };
}
