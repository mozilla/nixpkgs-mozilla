{
  description = "Mozilla related nixpkgs";

  edition = 201909;

  outputs = { self, nixpkgs }:
    let overlays = import ./overlays.nix;
    in {

      overlays = let
        inherit (builtins) listToAttrs;
        inherit (nixpkgs.lib) nameValuePair removeSuffix;

        nvPairs = map (overlay:
          nameValuePair
          (removeSuffix "-overlay.nix" "${baseNameOf (toString overlay)}")
          (import overlay)) overlays;

        overlayAttrs = listToAttrs nvPairs;

      in overlayAttrs;

    };
}
