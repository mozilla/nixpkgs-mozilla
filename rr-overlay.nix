self: super:

{
  # Add i686-linux platform as a valid target.
  rr = super.rr.override {
    gcc9Stdenv = self.gcc9Stdenv // {
      mkDerivation = args: self.gcc9Stdenv.mkDerivation (args // {
        meta = args.meta // {
          platforms = self.lib.platforms.linux;
        };
      });
    };
  };
}
