{ pkgs, inputs, config, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  virtualisation = {
    containers.enable = true;
    docker = {
        enable = true;
        daemon.settings = {metrics-addr = "0.0.0.0:9323"; experimental = true; };
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
}
