{
  description = "HIN Client";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks }:
    let
      name = "hinclient";

      hinclient = import ./default.nix;

      overlay = final: prev: {
        ${name} = final.callPackage hinclient { };
      };
    in
    flake-utils.lib.eachSystem
      [ "aarch64-linux" "i686-linux" "x86_64-linux" ]
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = { allowUnfree = true; };
          };
        in
        rec {

          apps.${name} = flake-utils.lib.mkApp { drv = packages.${name}; };

          defaultApp = apps.${name};

          packages.${name} = pkgs.callPackage hinclient { };

          defaultPackage = packages.${name};

          checks = {
            build = (
              import nixpkgs {
                inherit system;
                overlays = [ overlay ];
              }
            ).${name};

            pre-commit-check = pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks.nixpkgs-fmt.enable = true;
            };
          };

          nixosModule = ({ ... }: {
            nixpkgs.overlays = [ overlay ];
            imports = [ ./nixos-module.nix ];
          });

          devShell = pkgs.mkShell {
            inherit name;

            buildInputs = with pkgs; [
              # banner printing on enter
              figlet
              lolcat

              nixpkgs-fmt

              jdk8
              packages.${name}
            ];

            shellHook = ''
              figlet ${name} | lolcat --freq 0.5
              ${(checks.pre-commit-check).shellHook}
            '';
          };
        }) // {
      inherit overlay;
    };
}
