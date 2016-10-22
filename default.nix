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
        branch = "nixos-unstable";
        path = "pkgs/nixpkgs.json";
      };
    };

    gecko = callPackage ./pkgs/gecko { };

    servo = callPackage ./pkgs/servo { };

    firefox-dev-bin = import ./pkgs/firefox-dev-bin rec {
      inherit pkgs;
      inherit (pkgs) callPackage;
    };
  
    VidyoDesktop = callPackage ./pkgs/VidyoDesktop { };

  };

in mozpkgs
