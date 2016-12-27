{ pkgs }:

let
  update = import ./update.nix { inherit pkgs; };
in
  { inherit update; }
  // update
