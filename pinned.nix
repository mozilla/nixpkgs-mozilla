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

# Pin a specific version of Nixpkgs.
let
  _pkgs = import <nixpkgs> {};
  _pkgsPath =
    if pkgsPath != null then pkgsPath
    else _pkgs.fetchFromGitHub (_pkgs.lib.importJSON ./pkgs/nixpkgs.json);
  nixpkgs = import _pkgsPath ({
    overlays = import ./default.nix ++ overlays;
  } // (if system != null then { inherit system; } else {}));
in
  nixpkgs // {
    # Do not add a name attribute attribute in an overlay !!! As this will cause
    # tons of recompilations.
    name = "nixpkgs";
    updateScript = nixpkgs.lib.updateFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs-channels";
      branch = "nixos-unstable-small";
      path = "pkgs/nixpkgs.json";
    };
  }
