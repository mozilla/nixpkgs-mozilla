{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # nixpkgs-mozilla.url = "/local/path/to/nixpkgs-mozilla";
    nixpkgs-mozilla.url = "github:mozilla/nixpkgs-mozilla/master";
  };

  outputs = {nixpkgs, nixpkgs-mozilla, ...}:
  let
    latest = (import nixpkgs {
        overlays = [ nixpkgs-mozilla.overlays.firefox ];
        system = "x86_64-linux";
      }).latest;
  in {
    packages."x86_64-linux".default = latest.firefox-nightly-bin;
    packages."x86_64-linux".firefox-nightly = latest.firefox-nightly-bin;
    packages."x86_64-linux".firefox-beta = latest.firefox-beta-bin;
    packages."x86_64-linux".firefox-release = latest.firefox-release-bin;
    packages."x86_64-linux".firefox-esr = latest.firefox-esr-bin;
  };
}
