{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    # nixpkgs-mozilla.url = "/local/path/to/nixpkgs-mozilla/flakes";
    nixpkgs-mozilla.url = "github:mozilla/nixpkgs-mozilla/master?dir=flakes";
    nixpkgs-mozilla.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {nixpkgs-mozilla, ...}: {
    inherit (nixpkgs-mozilla) packages;
  };
}