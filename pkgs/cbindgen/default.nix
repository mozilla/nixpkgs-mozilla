### NOTE: This file is a copy of the one from Nixpkgs repository
### (taken 2018 October).  It is used when the version of cbindgen in
### upstream nixpkgs is not up-to-date enough to compile Firefox.
{ stdenv, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  name = "rust-cbindgen-${version}";
  version = "0.8.7";

  src = fetchFromGitHub {
    owner = "eqrion";
    repo = "cbindgen";
    rev = "v${version}";
    sha256 = "040rivayr0dgmrhlly5827c850xbr0j5ngiy6rvwyba5j9iv2x0y";
  };

  cargoSha256 = "1nig4891p7ii4z4f4j4d4pxx39f501g7yrsygqbpkr1nrgjip547";

  meta = with stdenv.lib; {
    description = "A project for generating C bindings from Rust code";
    homepage = https://github.com/eqrion/cbindgen;
    license = licenses.mpl20;
    maintainers = with maintainers; [ jtojnar ];
  };
}
