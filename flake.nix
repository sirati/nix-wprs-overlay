{
  description = "Overlay packaging the latest (master snapshot) of wprs, Wayland remote desktop";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      # Overlay that adds `wprs` to nixpkgs.
      overlays.default = final: prev: {
        wprs = final.callPackage ./package.nix { };
      };

      packages = forAllSystems (system: rec {
        wprs = (pkgsFor system).callPackage ./package.nix { };
        default = wprs;
      });

      devShells = forAllSystems (system: {
        default = (pkgsFor system).mkShellNoCC {
          inputsFrom = [ self.packages.${system}.wprs ];
        };
      });

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
