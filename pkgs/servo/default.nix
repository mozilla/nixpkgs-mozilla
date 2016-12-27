{ servoSrc ? null
, lib
, rustPlatform
, pkgs
}:

let

  inherit (lib) updateFromGitHub;
  inherit (pkgs) fetchFromGitHub curl dbus fontconfig freeglut freetype
    gperf libxmi llvm mesa mesa_glu openssl pkgconfig makeWrapper writeText
    xorg;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (pkgs.lib) importJSON;
  inherit (rustPlatform) buildRustPackage;
  inherit (rustPlatform.rust) rustc cargo;

  pythonPackages = pkgs.python3Packages;

  src =
    if servoSrc == null then
      fetchFromGitHub (importJSON ./source.json)
    else
      servoSrc;

  # TODO: figure out version from servoSrc
  version = "latest";

  # TODO: add possibility to test against wayland
  xorgCompositorLibs = "${xorg.libXcursor.out}/lib:${xorg.libXi.out}/lib";

  servobuild = writeText "servobuild" ''
    [tools]
    cache-dir = "./downloads"
    cargo-home-dir = "./.downloads/clones
    system-rust = true
    rust-root = "${rustc}/bin/rustc"
    system-cargo = true
    cargo-root = "${cargo}/bin/cargo"
    [build]
  '';

  servoRust = buildRustPackage rec {
    inherit src;
    name = "servo-rust-${version}";
    postUnpack = ''
      pwd
      ls -la 
      exit 100
    '';
    sourceRoot = "servo/components/servo";

    depsSha256 = "0ca0lc8mm8kczll5m03n5fwsr0540c2xbfi4nn9ksn0s4sap50yn";

    doCheck = false;
  };

in mkDerivation rec {
  name = "servo-${version}";
  src = servoSrc;

  buildInputs = [
    #cmake
    curl
    dbus
    fontconfig
    freeglut
    freetype
    gperf
    libxmi
    llvm
    mesa
    mesa_glu
    openssl
    pkgconfig
    pythonPackages.pip
    pythonPackages.virtualenv
    xorg.libX11
    xorg.libXmu

    # nix stuff
    makeWrapper
    servoRust
  ];
  preConfigure = ''
    ln -s ${servobuild} .servobuild
  '';
  postInstall = ''
    wrapProgram "$out/bin/servo" --prefix LD_LIBRARY_PATH : "${xorgCompositorLibs}"
  '';
  shellHook = ''
    # Servo tries to switch between libX11 and wayland at runtime so we have
    # to provide a path
    export LD_LIBRARY_PATH=${xorgCompositorLibs}:$LD_LIBRARY_PATH
  '';
  passthru.updateScript = updateFromGitHub {
    owner = "servo";
    repo = "servo";
    branch = "master";
    path = "pkgs/servo/source.json";
  };
}
