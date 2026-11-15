{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libxkbcommon,
  wayland,
  zstd,
  makeWrapper,
  python3,
  openssh,
  xwayland,
  # Set to `true` to build with the upstream `release-lto` profile. It produces
  # noticeably faster binaries (upstream calls non-release builds "unusably
  # slow") at the cost of a much longer, single-threaded LTO build.
  withLto ? false,
}:

let
  # The `wprs` launcher is a python3 script that shells out to `ssh` and to the
  # `wprsc` binary (looked up on PATH), so its runtime environment needs both.
  pythonEnv = python3.withPackages (ps: [ ps.psutil ]);
in
rustPlatform.buildRustPackage rec {
  pname = "wprs";
  # Upstream has no tags/releases; this is a snapshot of the master branch.
  version = "0.1.0-unstable-2026-04-16";

  src = fetchFromGitHub {
    owner = "wayland-transpositor";
    repo = "wprs";
    rev = "57139a03abf466c5f24b737835a61121bd25c8c0";
    hash = "sha256-1QXy0VNYCDyuUC4EUEnFKYC4RtADegR1aXwv/gRNmy8=";
  };

  # Cargo.lock is committed upstream and contains no git sources, so importing
  # it directly needs no per-dependency outputHashes and no cargoHash to churn
  # on every bump.
  cargoLock.lockFile = "${src}/Cargo.lock";

  buildType = if withLto then "release-lto" else "release";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  # zstd: nixpkgs' cargo hook has zstd-sys link the system library.
  buildInputs = [
    libxkbcommon
    wayland
    zstd
  ];

  # Builds the wprsc / wprsd / xwayland-xdg-shell bin targets automatically.
  # Install the python launcher and the systemd user unit by hand.
  postInstall = ''
    install -Dm755 wprs $out/bin/wprs

    install -Dm644 wprsd.service $out/lib/systemd/user/wprsd.service
    substituteInPlace $out/lib/systemd/user/wprsd.service \
      --replace-fail /usr/bin/wprsd $out/bin/wprsd
  '';

  postFixup = ''
    wrapProgram $out/bin/wprs \
      --prefix PATH : ${lib.makeBinPath [ pythonEnv openssh xwayland ]} \
      --prefix PATH : $out/bin
  '';

  meta = {
    description = "Rootless remote desktop access for remote Wayland (Xpra-style)";
    homepage = "https://github.com/wayland-transpositor/wprs";
    license = lib.licenses.asl20;
    mainProgram = "wprs";
    # The .cargo/config.toml pins target-cpu=x86-64-v3 on x86_64 (AVX2 era CPUs).
    # aarch64 builds without that flag. Darwin is unsupported (needs Wayland).
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
