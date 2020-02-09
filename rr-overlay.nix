final: prev:

{
  # Add i686-linux platform as a valid target.
  rr = prev.rr.override {
    stdenv = final.stdenv // {
      mkDerivation = args: final.stdenv.mkDerivation (args // {
        meta = args.meta // {
          platforms = final.stdenv.lib.platforms.linux;
        };
      });
    };
  };
}
