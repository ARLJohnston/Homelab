{
  inputs = {
    nixpkgs.url = "github:nixOS/nixpkgs";
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
  };
  outputs = {
    nixpkgs,
    ...
  } @ inputs: {
    nixosConfigurations = {
      hephaestus = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        system = "x86_64-linux";
        modules = [
          {
            config.system.stateVersion = "25.05";
          }
          ./virtualisation.nix
          ./system.nix
          inputs.comin.nixosModules.comin
          ({...}: {
            services.comin = {
              enable = true;
              remotes = [
                {
                  name = "origin";
                  url = "https://github.com/ARLJohnston/Homelab.git";
                  branches.main.name = "main";
                }
              ];
              hostname = "hephaestus";
            };
          })
        ];
      };
    };
  };
}
