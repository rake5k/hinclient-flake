# HIN Client Flake

[![Build and Test][ci-badge]][ci]

The HIN Client is the access software for easy and secure access to the [HIN
platform](https://www.hin.ch/). This software is installed on the workstations and thus enables HIN
participants to securely access HIN protected web applications and the HIN email services.

## Usage

**Prerequisites**: You need your `JAVA_HOME` pointing to a Java 8 runtime and a [flakes-enabled
`nix`](https://nixos.wiki/wiki/Flakes#Installing_flakes).

### Directly

To fire off a HIN client instance quickly, just use this command:

```bash
# If you do not have Java 8 installed, run a nix shell containing it:
nix shell nixpkgs#jre8

nix run github:christianharke/hinclient-flake#.
```

### NixOS Overlay

For just installing the `hinclient` binary on NixOS, this flake needs to be added to the `inputs`
and its `overlay` registered in the `pkgs` overlay.

**Example**

```nix
# flake.nix

{
  description = "HIN client flake demo";

  inputs.hinclient.url = "github:christianharke/hinclient-flake";

  outputs = { self, nixpkgs, hinclient }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [
          hinclient.overlay
        ];
      };
    in
    {
      nixosConfigurations = {
        # ...
      };

      devShell = pkgs.mkShell {
        name = "my-dev-shell";

        buildInputs = with pkgs; [
          pkgs.hinclient
        ];
      };
    };
}
```

### NixOS Module

To get the HIN client installed as a global [SystemD](https://systemd.io/) service, there is an
optional `nixosModule`, which just needs to be registered in the `nixosConfiguration`.

**Example**

```nix
# flake.nix

{
  description = "HIN client flake demo";

  inputs.hinclient.url = "github:christianharke/hinclient-flake";

  outputs = { self, nixpkgs, hinclient }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
    in
    {
      nixosConfigurations = {
        mycomputer = nixpkgs.lib.nixosSystem {
          inherit system pkgs;
          specialArgs = { inherit self system; };
          modules = [
            my-module.nix
            # Some other modules...
            
            # Add this line:
            hinclient.nixosModule
          ];
        };
      };
    };
}
```

```nix
# my-module.nix

{ config, ... }:

{
  services.hinclient = {
    enable = true;
    identities = "my-hin-identities";

    # Watch out, settings like these will be stored in the world
    # readable nix store in plaintext (on your local drive)!
    passphrase = "my-hin-identity-passphrase"; 
    keystore = "my-hin-identity-file";
    language = "en";
  };
}
```

After a `nixos-rebuild switch`, there will be a systemD service which can be started via `systemctl
start hinclient.service`.

[ci]: https://github.com/christianharke/hinclient-flake/actions/workflows/ci.yml
[ci-badge]: https://github.com/christianharke/hinclient-flake/actions/workflows/ci.yml/badge.svg

