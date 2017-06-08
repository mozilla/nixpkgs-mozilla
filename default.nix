# This script extends nixpkgs with mozilla packages.
#
# First it imports the <nixpkgs> in the environment and depends on it
# providing fetchFromGitHub and lib.importJSON.
#
# After that it loads a pinned release of nixos-unstable and uses that as the
# base for the rest of packaging. One can pass it's own pkgs attribute if
# desired, probably in the context of hydra.
let
  _pkgs = import <nixpkgs> {};
  _nixpkgs = _pkgs.fetchFromGitHub (_pkgs.lib.importJSON ./pkgs/nixpkgs.json);
in

{ pkgs ? import _nixpkgs {}
, geckoSrc ? null
, servoSrc ? null
}:

let
  callPackage = (extra: pkgs.lib.callPackageWith
    ({ inherit geckoSrc servoSrc; } // self // extra)) {};

  self = {

    lib = callPackage ./pkgs/lib/default.nix { };

    rustPlatform = pkgs.rustUnstable;

    pkgs = pkgs // {
      name = "nixpkgs";
      updateScript = self.lib.updateFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs-channels";
        branch = "nixos-unstable";
        path = "pkgs/nixpkgs.json";
      };
    };

    gecko = callPackage ./pkgs/gecko { };

    servo = callPackage ./pkgs/servo { };

    firefox-nightly-bin = callPackage ./pkgs/firefox-nightly-bin/default.nix { };
  
    VidyoDesktop = callPackage ./pkgs/VidyoDesktop { };

  };

in self
