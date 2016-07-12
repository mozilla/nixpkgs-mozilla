{ pkgs ? import <nixpkgs> {}
, geckoSrc ? null
, servoSrc ? null
}:

let

  rustPlatform = pkgs.recurseIntoAttrs (pkgs.makeRustPlatform pkgs.rustUnstable rustPlatform);

  pkgs_mozilla = {

    nixpkgs = pkgs;

    lib = import ./lib/default.nix { inherit pkgs_mozilla; };
  
    gecko = import ./pkgs/gecko {
      inherit geckoSrc;
      inherit (pkgs_mozilla.lib) updateFromGitHub;
      inherit (pkgs)
        stdenv lib
        pythonFull which autoconf213
        perl unzip zip gnumake yasm pkgconfig
        xlibs gnome
        pango
        dbus dbus_glib
        alsaLib libpulseaudio gstreamer gst_plugins_base
        gtk3 glib gobjectIntrospection
        valgrind gdb rr
        fetchFromGitHub;
    };
  
    servo = import ./pkgs/servo {
      pythonPackages = pkgs.python3Packages;
      inherit servoSrc rustPlatform;
      inherit (pkgs_mozilla.lib) updateFromGitHub;
      inherit (pkgs) stdenv lib fetchFromGitHub
        curl dbus fontconfig freeglut freetype gperf libxmi llvm mesa
        mesa_glu openssl pkgconfig makeWrapper writeText xorg;
    };
  
    VidyoDesktop = import ./pkgs/VidyoDesktop {
      inherit (pkgs) stdenv fetchurl buildFHSUserEnv makeWrapper dpkg alsaLib
        alsaUtils alsaOss alsaTools alsaPlugins libidn utillinux mesa_glu qt4
        zlib patchelf xorg;
    };

  };

in pkgs_mozilla
