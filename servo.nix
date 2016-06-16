{ version ? "master" 
}:

let
  pkgs = import <nixpkgs> {};
  inherit (pkgs) stdenv;

  # TODO: add wayland
  xorgCompositorLibs = "${pkgs.xorg.libXcursor.out}/lib:${pkgs.xorg.libXi.out}/lib";

  rustc = pkgs.rustcUnstable;
  cargo = pkgs.cargoUnstable;

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

in stdenv.mkDerivation rec {
  name = "servo-${version}";
  src = ./.;
  buildInputs = with pkgs; [
    cmake
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
  ];
  preConfigure = ''
    ln -s ${servobuild} .servobuild
    cat .servobuild
    exit 100
  '';
  postInstall = ''
    wrapProgram "$out/bin/servo" --prefix LD_LIBRARY_PATH : "${xorgCompositorLibs}"
  '';
  shellHook = ''
    export LD_LIBRARY_PATH=${xorgCompositorLibs}:$LD_LIBRARY_PATH
  '';

}
