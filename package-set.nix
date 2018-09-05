{ pkgs }:

with pkgs.lib;
let
  self = foldl'
    (prev: overlay: prev // (overlay (pkgs // self) (pkgs // prev)))
    {} (map import (import ./overlays.nix));
in self
