{ pkg ? null
, pkgs ? null
}:

let
  pkgs_mozilla = import ./default.nix { inherit pkgs; };
  packages = if pkg == null
    then pkgs_mozilla.lib.packagesToUpdate
    else [(builtins.getAttr pkg pkgs_mozilla).updateSrc];
in pkgs_mozilla.nixpkgs.stdenv.mkDerivation {
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
