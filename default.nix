# Nixpkgs overlay which aggregates overlays for tools and products, used and
# published by Mozilla.
self: super:

with super.lib;

(foldl' (flip extends) (_: super) [

  (import ./lib-overlay.nix)
  (import ./rust-overlay.nix)
  (import ./firefox-overlay.nix)
  (import ./vidyo-overlay.nix)
  (import ./servo-overlay.nix)

]) self
