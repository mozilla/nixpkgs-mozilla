{
  description = "Mozilla overlay for Nixpkgs";

  outputs = { self, ... }: {
    # Default overlay.
    overlay = import ./default.nix;

    # Inidividual overlays.
    overlays = {
      lib = import ./lib-overlay.nix;
      rust = import ./rust-overlay.nix;
      firefox = import ./firefox-overlay.nix;
      git-cinnabar = import ./git-cinnabar-overlay.nix;
    };
  };
}
