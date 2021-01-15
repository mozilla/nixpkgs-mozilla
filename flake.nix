{
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      inherit (builtins) listToAttrs;
      inherit (nixpkgs.lib) genAttrs nameValuePair removeSuffix;

      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      overlays =
        listToAttrs (
          map
            (overlay:
              nameValuePair
                (removeSuffix "-overlay.nix" "${baseNameOf (toString overlay)}")
                (import overlay)
            )
            (import ./overlays.nix));

      packages = forAllSystems (system:
        import ./package-set.nix { pkgs = import nixpkgs { inherit system; }; }
      );
    };
}
