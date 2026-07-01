# wprs-overlay

A Nix overlay/flake packaging the **latest** [`wprs`](https://github.com/wayland-transpositor/wprs)
— rootless remote-desktop access for Wayland (Xpra-style: run remote Wayland/X11
apps over an SSH tunnel and have them appear in your local compositor).

nixpkgs ships an old snapshot (`0-unstable-2025-09-05`) and does not wrap the
`wprs` launcher, so `wprs` is effectively unusable there. This overlay tracks a
much newer master commit and packages it properly:

- Pinned to master **`57139a0`** (2026-04-16) — upstream has no tags/releases.
- Builds all three binaries: `wprsc`, `wprsd`, `xwayland-xdg-shell`.
- Wraps the `wprs` python launcher with `python3` + `psutil`, `openssh`, and
  `xwayland` on `PATH`, so it works out of the box.
- Installs the `wprsd.service` systemd **user** unit (patched to the store path)
  under `share/systemd/user`.

## Usage

### Flake — run directly

```sh
nix run github:sirati/nix-wprs-overlay
# or, for the daemon:
nix run github:sirati/nix-wprs-overlay#default -- --help
```

### Flake — as an overlay in your NixOS / home-manager config

```nix
{
  inputs.wprs-overlay.url = "github:sirati/nix-wprs-overlay";

  # in your nixpkgs config:
  nixpkgs.overlays = [ inputs.wprs-overlay.overlays.default ];
  environment.systemPackages = [ pkgs.wprs ];   # NixOS
  # or  home.packages = [ pkgs.wprs ];           # home-manager
}
```

`pkgs.wprs` then provides `wprs`, `wprsc`, `wprsd`, and `xwayland-xdg-shell`.

### Classic (non-flake) Nix

```nix
# configuration.nix
{
  nixpkgs.overlays = [ (import /path/to/wprs-overlay/overlay.nix) ];
  environment.systemPackages = [ pkgs.wprs ];
}
```

### systemd user service (server side)

```sh
systemctl --user enable --now wprsd.service   # unit shipped in share/systemd/user
```

## Options

The derivation takes a `withLto` argument (default `false`). Upstream's
`release-lto` profile yields faster binaries but a much slower single-threaded
build:

```nix
pkgs.wprs.override { withLto = true; }
```

> **Note:** on x86_64 the binaries are built with `target-cpu=x86-64-v3`
> (upstream's `.cargo/config.toml`), so they require an AVX2-class CPU.
> `aarch64-linux` builds without that restriction. Darwin is unsupported
> (wprs needs Wayland).

## Updating to a newer commit

1. Bump `rev` (and `version` date) in `package.nix`.
2. Recompute the source hash:
   ```sh
   nix-prefetch-url --unpack https://github.com/wayland-transpositor/wprs/archive/<rev>.tar.gz \
     | tail -1 | xargs nix hash convert --hash-algo sha256
   ```
3. `cargoLock.lockFile` reads the lockfile straight from the fetched source, so
   as long as upstream keeps `Cargo.lock` committed with no git sources, nothing
   else needs updating.
