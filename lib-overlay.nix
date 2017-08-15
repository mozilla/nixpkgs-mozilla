self: super:

{
  lib = super.lib // (import ./pkgs/lib/default.nix { pkgs = self; });
}
