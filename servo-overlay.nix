self: super:

{
  rustPlatform = self.rustUnstable;
  servo = super.callPackage ./pkgs/servo { };
}
