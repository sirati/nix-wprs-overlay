# Classic (non-flake) overlay. Usage:
#   nixpkgs.overlays = [ (import ./overlay.nix) ];
# or with a pinned fetch of this repo.
final: prev: {
  wprs = final.callPackage ./package.nix { };
}
