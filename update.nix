let
  _pkgs = import <nixpkgs> {};
  _nixpkgs = _pkgs.fetchFromGitHub (_pkgs.lib.importJSON ./pkgs/nixpkgs.json);
in

{ pkgs ? import _nixpkgs {}
, pkg ? null
}:

let
  nixpkgs-mozilla = import ./default.nix { inherit pkgs; };
  packages = if pkg == null
    then nixpkgs-mozilla.lib.packagesToUpdate
    else [(builtins.getAttr pkg nixpkgs-mozilla).updateSrc];
in nixpkgs-mozilla.nixpkgs.stdenv.mkDerivation {
  name = "update-nixpkgs-mozilla";
  buildCommand = ''
    echo "+--------------------------------------------------------+"
    echo "| Not possible to update repositories using \`nix-build\`. |"
    echo "|         Please run \`nix-shell update.nix\`.             |"
    echo "+--------------------------------------------------------+"
    exit 1
  '';
  shellHook = ''
    export HOME=$PWD
    ${builtins.concatStringsSep "\n\n" packages}
    echo "Packages updated!"
    exit
  '';
}
