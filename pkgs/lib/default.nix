{ nixpkgs-mozilla }:

let
  update = import ./update.nix { inherit nixpkgs-mozilla; };
in
  { inherit update; }
  // update
