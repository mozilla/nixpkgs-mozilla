self: super:

{
  # Add i686-linux platform as a valid target.
  rr = super.rr.override {
    stdenv = self.stdenv // {
      mkDerivation = args: self.stdenv.mkDerivation (args // {
        meta = args.meta // {
          platforms = self.lib.platforms.linux;
        };
      });
    };
  };
}
