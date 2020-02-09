final: prev:

{
  lib = prev.lib // (import ./pkgs/lib/default.nix { pkgs = final; });
}
