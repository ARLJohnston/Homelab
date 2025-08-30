{
  pkgs,
  inputs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [
    alejandra
    curl
    git
  ];

  networking.hostName = "hephaestus";
  users = {
    users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKklwiiuDNGd0+OdLJ8WsMJ+3ZgxCXpvWh2si4AwMzSv"];
    users.root.initialHashedPassword = "";
  };
  services.getty.autologinUser = "root";

  networking = {
    networkmanager.enable = true;
  };

  virtualisation = {
    containers.enable = true;
    docker = {
      enable = true;
      daemon.settings = {
        metrics-addr = "0.0.0.0:9323";
        experimental = true;
      };
    };
  };

  services.prometheus = {
    enable = true;
    port = 9090;

    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };

    exporters = {
      node.enable = true;
      systemd.enable = true;
    };

    scrapeConfigs = [
      {
        job_name = "Docker";
        static_configs = [
          {
            targets = ["localhost:9323"];
          }
        ];
      }
      {
        job_name = "Comin";
        static_configs = [
          {
            targets = ["localhost:4243"];
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      security.admin_password = "";
      server = {
        http_addr = "localhost";
        http_port = 3000;
      };
    };
  };

  boot.kernelParams = [
    "cgroup_enable=cpuset"
    "cgroup_memory=1"
    "cgroup_enable=memory"
  ];
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [3000 9090];
  };
}
