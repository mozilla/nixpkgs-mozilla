# This script extends nixpkgs with mozilla packages.
#
# First it imports the <nixpkgs> in the environment and depends on it
# providing fetchFromGitHub and lib.importJSON.
#
# After that it loads a pinned release of nixos-16.09 and uses that as the
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
    ({ inherit geckoSrc servoSrc; } // mozpkgs // extra)) {};

  mozpkgs = {

    lib = import ./pkgs/lib/default.nix { inherit mozpkgs; };

    rustPlatform = pkgs.recurseIntoAttrs (
      pkgs.makeRustPlatform
      pkgs.rustUnstable
      mozpkgs.rustPlatform
    );

    nixpkgs = pkgs // {
      updateSrc = mozpkgs.lib.updateFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs-channels";
        branch = "nixos-16.09";
        path = "pkgs/nixpkgs.json";
      };
    };

    gecko = callPackage ./pkgs/gecko { };

    servo = callPackage ./pkgs/servo { };

    firefox-dev-bin = callPackage ./pkgs/firefox-dev-bin {
      inherit pkgs;
    };
  
    VidyoDesktop = callPackage ./pkgs/VidyoDesktop { };

  };

in mozpkgs
