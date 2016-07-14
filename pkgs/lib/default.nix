{ pkgs_mozilla }:

let
  update = import ./update.nix { inherit pkgs_mozilla; };
in
  { inherit update; }
  // update
