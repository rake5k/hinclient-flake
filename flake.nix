{
  description = "HIN Client";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { self, nixpkgs, pre-commit-hooks }:
    let
      name = "hinclient";

      hinclient = import ./default.nix;

      # System types to support.
      supportedSystems = [ "x86_64-darwin" "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      });
    in
    {

      apps = forAllSystems (system: {
        ${name} = {
          type = "app";
          program = "${self.packages.${system}.${name}}/bin/hinclient";
        };
        default = self.apps.${system}.${name};
      });

      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          ${name} = pkgs.callPackage hinclient { };
          default = self.packages.${system}.${name};
        });

      overlays.default = final: prev: {
        ${name} = self.packages.${prev.system}.default;
      };

      checks = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          build = self.packages.${system}.${name};

          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              statix.enable = true;
            };
          };
        });

      nixosModules.default = { config, ... }: {
        nixpkgs.overlays = [ self.overlays.default ];
        imports = [ ./nixos-module.nix ];
      };

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            inherit name;

            buildInputs = with pkgs; [
              # banner printing on enter
              figlet
              lolcat

              nixpkgs-fmt
              statix

              jdk8
              self.packages.${system}.${name}
            ];

            shellHook = ''
              figlet ${name} | lolcat --freq 0.5
              ${self.checks.${system}.pre-commit-check.shellHook}
            '';
          };
        });
    };
}
