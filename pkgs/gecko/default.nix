{ geckoSrc ? null, lib
, stdenv, fetchFromGitHub, pythonFull, which, autoconf213
, perl, unzip, zip, gnumake, yasm, pkgconfig, xlibs, gnome2, pango
, dbus, dbus_glib, alsaLib, libpulseaudio, gstreamer, gst_plugins_base
, gtk3, glib, gobjectIntrospection, git, mercurial, openssl, cmake, procps
, libnotify
, valgrind, gdb, rr
, setuptools
, rust # rust & cargo bundled. (otheriwse use pkgs.rust.{rustc,cargo})
, buildFHSUserEnv # Build a FHS environment with all Gecko dependencies.
, clang
, ccache
}:

let

  inherit (lib) updateFromGitHub importJSON optionals inNixShell;

  # Gecko sources are huge, we do not want to import them in the nix-store when
  # we use this expression for making a build environment.
  src =
    if inNixShell then
      null
    else if geckoSrc == null then
      fetchFromGitHub (importJSON ./source.json)
    else
      geckoSrc;

  version = "HEAD"; # XXX: builtins.readFile "${src}/browser/config/version.txt";

  buildInputs = [

    # Expected by "mach"
    pythonFull setuptools which autoconf213

    # Expected by the configure script
    perl unzip zip gnumake yasm pkgconfig

    xlibs.libICE xlibs.libSM xlibs.libX11 xlibs.libXau xlibs.libxcb
    xlibs.libXdmcp xlibs.libXext xlibs.libXt xlibs.printproto
    xlibs.renderproto xlibs.xextproto xlibs.xproto xlibs.libXcomposite
    xlibs.compositeproto xlibs.libXfixes xlibs.fixesproto
    xlibs.damageproto xlibs.libXdamage xlibs.libXrender xlibs.kbproto

    gnome2.libart_lgpl gnome2.libbonobo gnome2.libbonoboui
    gnome2.libgnome gnome2.libgnomecanvas gnome2.libgnomeui
    gnome2.libIDL

    pango

    dbus dbus_glib

    alsaLib libpulseaudio
    gstreamer gst_plugins_base

    gtk3 glib gobjectIntrospection

    rust

    # For building bindgen
    clang

    # mach mochitest
    procps

    # "mach vendor rust" wants to list modified files by using the vcs.
    git mercurial

    # needed for compiling cargo-vendor and its dependencies
    openssl cmake

    # Useful for getting notification at the end of the build.
    libnotify

  ] ++ optionals inNixShell [
    valgrind gdb rr ccache
  ];

  shellHook = ''
    export MOZBUILD_STATE_PATH=$PWD/.mozbuild
    export CC="${stdenv.cc}/bin/cc";
    export CXX="${stdenv.cc}/bin/c++";
  '';

  # propagatedBuildInput should already have applied the "lib.chooseDevOutputs"
  # on the propagated build inputs.
  pullAllInputs = inputs:
    inputs ++ lib.concatMap (i: pullAllInputs (i.propagatedNativeBuildInputs or [])) inputs;

  fhs = buildFHSUserEnv {
    name = "gecko-deps-fhs";
    targetPkgs = _: pullAllInputs (lib.chooseDevOutputs (buildInputs ++ [ stdenv.cc ]));
    multiPkgs = null;
    extraOutputsToInstall = [ "share" ];
    profile = ''
      # build-fhs-userenv/env.nix adds it, but causes 'ls' to SEGV.
      unset LD_LIBRARY_PATH;
      export IN_NIX_SHELL=1
      export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig
      ${shellHook}
    '';
  };
in

stdenv.mkDerivation {
  name = "gecko-dev-${version}";
  inherit src buildInputs shellHook;

  # Useful for debugging this Nix expression.
  tracePhases = true;

  configurePhase = ''
    export MOZBUILD_STATE_PATH=$(pwd)/.mozbuild
    export MOZ_CONFIG=$(pwd)/.mozconfig
    export builddir=$(pwd)/builddir

    mkdir -p $MOZBUILD_STATE_PATH $builddir
    echo > $MOZ_CONFIG "
    . $src/build/mozconfig.common

    mk_add_options MOZ_OBJDIR=$builddir
    mk_add_options AUTOCONF=${autoconf213}/bin/autoconf
    ac_add_options --prefix=$out
    ac_add_options --enable-application=browser
    ac_add_options --enable-official-branding
    export AUTOCONF=${autoconf213}/bin/autoconf
    "
  '';

  AUTOCONF = "${autoconf213}/bin/autoconf";

  buildPhase = ''
    cd $builddir
    $src/mach build
  '';

  installPhase = ''
    cd $builddir
    $src/mach install
  '';

  # TODO: are there tests we would like to run? or should we package them separately?
  doCheck = false;
  doInstallCheck = false;

  # This is for debugging purposes, go to hell damn wrapper which are removing
  # all I need for debugging.
  hardeningDisable = [ "all" ];

  passthru.updateScript = updateFromGitHub {
    owner = "mozilla";
    repo = "gecko-dev";
    branch = "master";
    path = "pkgs/gecko/source.json";
  };
  passthru.fhs = fhs; # gecko.x86_64-linux.gcc.fhs.env
}
