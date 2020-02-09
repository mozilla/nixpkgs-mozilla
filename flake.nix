{
  description = "Mozilla related nixpkgs";

  edition = 201909;

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      overlays = import ./overlays.nix;
      pkgs = import nixpkgs { inherit system; };
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

      packages."${system}" = import ./package-set.nix { inherit pkgs; };

    };
}
