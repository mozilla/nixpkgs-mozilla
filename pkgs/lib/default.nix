{ mozpkgs }:

let
  update = import ./update.nix { inherit mozpkgs; };
in
  { inherit update; }
  // update
