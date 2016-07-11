{ pkgs ? import <nixpkgs> {}

, geckoSrc ?
    pkgs.fetchFromGitHub {
      owner = "mozilla";
      repo = "gecko-dev";
      rev = "bcd7fc0f642b97c9b0a2618750e1788547aa8322";
      sha256 = "1knrffx62i8zfg3jfhpn3hs5354sg44f8iq4c7hfvp4nsxsjskr4";
    }

, servoSrc ? null
}:

let

  rustPlatform = pkgs.recurseIntoAttrs (pkgs.makeRustPlatform pkgs.rustUnstable rustPlatform);

  self = {

  
    gecko = import ./pkgs/gecko {
      inherit geckoSrc;
      inherit (pkgs)
        stdenv
        pythonFull which autoconf213
        perl unzip zip gnumake yasm pkgconfig
        xlibs gnome
        pango
        dbus dbus_glib
        alsaLib libpulseaudio gstreamer gst_plugins_base
        gtk3 glib gobjectIntrospection
        valgrind;
    };
  
    servo = import ./pkgs/servo {
      pythonPackages = pkgs.python3Packages;
      inherit servoSrc rustPlatform;
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

in self
