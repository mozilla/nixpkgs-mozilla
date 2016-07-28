{ pkgs ? null
, geckoSrc ? null
, servoSrc ? null
}:

let

  _pkgs = import <nixpkgs> {};

  _nixpkgs = if pkgs == null
    then (import (_pkgs.fetchFromGitHub (_pkgs.lib.importJSON ./pkgs/nixpkgs.json)) {})
    else pkgs;

  pkgs_mozilla = {

    lib = import ./pkgs/lib/default.nix { inherit pkgs_mozilla; };

    rustPlatform = pkgs_mozilla.nixpkgs.recurseIntoAttrs (
      pkgs_mozilla.nixpkgs.makeRustPlatform
      pkgs_mozilla.nixpkgs.rustUnstable
      pkgs_mozilla.rustPlatform
    );

    nixpkgs = _nixpkgs // {
      updateSrc = pkgs_mozilla.lib.updateFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs-channels";
        branch = "nixos-unstable";
        path = "pkgs/nixpkgs.json";
      };
    };

    gecko = import ./pkgs/gecko {
      inherit geckoSrc;
      inherit (pkgs_mozilla.lib) updateFromGitHub;
      inherit (pkgs_mozilla.nixpkgs)
        stdenv lib
        pythonFull setuptools which autoconf213
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
      pythonPackages = pkgs_mozilla.nixpkgs.python3Packages;
      inherit servoSrc;
      inherit (pkgs_mozilla) rustPlatform;
      inherit (pkgs_mozilla.lib) updateFromGitHub;
      inherit (pkgs_mozilla.nixpkgs) stdenv lib fetchFromGitHub
        curl dbus fontconfig freeglut freetype gperf libxmi llvm mesa
        mesa_glu openssl pkgconfig makeWrapper writeText xorg;
    };
  
    VidyoDesktop = import ./pkgs/VidyoDesktop {
      inherit (pkgs_mozilla.nixpkgs) stdenv fetchurl buildFHSUserEnv makeWrapper dpkg alsaLib
        alsaUtils alsaOss alsaTools alsaPlugins libidn utillinux mesa_glu qt4
        zlib patchelf xorg;
    };

  };

in pkgs_mozilla
