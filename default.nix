# This script extends nixpkgs with mozilla packages.
#
# First it imports the <nixpkgs> in the environment and depends on it
# providing fetchFromGitHub and lib.importJSON.
#
# After that it loads a pinned release of nixos-unstable and uses that as the
# base for the rest of packaging. One can pass it's own pkgsPath attribute if
# desired, probably in the context of hydra.

{ pkgsPath ? null
, overlays ? []
, system ? null
, geckoSrc ? null
, servoSrc ? null
}:

let
  _pkgs = import <nixpkgs> {};
  _pkgsPath =
    if pkgsPath != null then pkgsPath
    else _pkgs.fetchFromGitHub (_pkgs.lib.importJSON ./pkgs/nixpkgs.json);

  overlay = self: super: {
    lib = super.lib // (import ./pkgs/lib/default.nix { pkgs = self; });

    rustPlatform = self.rustUnstable;

    name = "nixpkgs";
    updateScript = self.lib.updateFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs-channels";
      branch = "nixos-unstable";
      path = "pkgs/nixpkgs.json";
    };

    gecko = super.callPackage ./pkgs/gecko {
      inherit (self.pythonPackages) setuptools;
      inherit (self.rustChannels.stable) rust;
    };

    servo = super.callPackage ./pkgs/servo { };

    firefox-developer-bin = super.callPackage ./pkgs/firefox-bin/default.nix { channel = "developer"; };
    firefox-nightly-bin = super.callPackage ./pkgs/firefox-bin/default.nix { channel = "nightly"; };

    VidyoDesktop = super.callPackage ./pkgs/VidyoDesktop { };
  };
in

import _pkgsPath {
  overlays = [
    (import ./rust-overlay.nix)
    overlay
  ] ++ overlays;
}
