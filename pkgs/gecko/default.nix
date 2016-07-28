{ geckoSrc ? null
, updateFromGitHub
, stdenv, lib
, pythonFull, setuptools, which, autoconf213
, perl, unzip, zip, gnumake, yasm, pkgconfig
, xlibs, gnome
, pango
, dbus, dbus_glib
, alsaLib, libpulseaudio, gstreamer, gst_plugins_base
, gtk3, glib, gobjectIntrospection
, valgrind, gdb, rr
, fetchFromGitHub
}:

let

  # Gecko sources are huge, we do not want to import them in the nix-store when
  # we use this expression for making a build environment.
  src =
    if geckoSrc == null then
      fetchFromGitHub (lib.importJSON ./source.json)
    else
      geckoSrc;

  # TODO: figure out version from geckoSrc
  version = "latest";

in stdenv.mkDerivation {
  name = "firefox-${version}";
  inherit src;
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

    gnome.libart_lgpl gnome.libbonobo gnome.libbonoboui
    gnome.libgnome gnome.libgnomecanvas gnome.libgnomeui
    gnome.libIDL

    pango

    dbus dbus_glib

    alsaLib libpulseaudio
    gstreamer gst_plugins_base

    gtk3 glib gobjectIntrospection

  ] ++ stdenv.lib.optionals stdenv.lib.inNixShell [
    valgrind gdb rr
  ];

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

  shellHook = ''
    export MOZBUILD_STATE_PATH=$PWD/.mozbuild
  '';
  passthru.updateSrc = updateFromGitHub {
    owner = "mozilla";
    repo = "gecko-dev";
    branch = "master";
    path = "pkgs/gecko/source.json";
  };
}
