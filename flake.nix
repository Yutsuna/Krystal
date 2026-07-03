{
  description = "Krystal is a crystal compiler wrapper for big projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          pkgs,
          ...
        }:
        {
          packages.default =
            with pkgs;
            crystal.buildCrystalPackage {
              pname = "krystal";
              version = "0.1.0";
              src = ./.;
              format = "shards";
              shardsRepo = null;
              buildTargets = [ "Source/Krystal.cr" ];
            };
          devShells.default =
            with pkgs;
            mkShell {
              packages = with pkgs; [
                crystal
                shards
              ];
            };
        };
    };
}
