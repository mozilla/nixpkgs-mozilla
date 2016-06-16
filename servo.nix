{ version ? "master" 
}:

let
  pkgs = import <nixpkgs> {};
  inherit (pkgs) stdenv;

  # Where the servo codes lives 
  servoSrc = ../../servo/servo;

  # TODO: add wayland
  xorgCompositorLibs = "${pkgs.xorg.libXcursor.out}/lib:${pkgs.xorg.libXi.out}/lib";

  rust = pkgs.rustUnstable;
  rustc = rust.rustc;
  cargo = rust.cargo;

  servobuild = pkgs.writeText "servobuild" ''
    [tools]
    cache-dir = "./downloads"
    cargo-home-dir = "./.downloads/clones
    system-rust = true
    rust-root = "${rustc}/bin/rustc"
    system-cargo = true
    cargo-root = "${cargo}/bin/cargo"
    [build]
  '';

  servoRust = rust.buildRustPackage {
    name = "servo-rust-${version}";
    src = servoSrc;
    postUnpack = ''
      pwd
      ls -la cargo-*
    '';
    sourceRoot = "cargo-*/components/servo";

    depsSha256 = "0ca0lc8mm8kczll5m03n5fwsr0540c2xbfi4nn9ksn0s4sap50yn";

    doCheck = false;
  };

in stdenv.mkDerivation rec {
  name = "servo-${version}";
  src = servoSrc;
  buildInputs = with pkgs; [
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
    openssl
    pkgconfig
    python3Packages.pip
    python3Packages.virtualenv
    xorg.libX11
    xorg.libXmu

    # nixstuff
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

}
