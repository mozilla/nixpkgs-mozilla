### NOTE: This file is a copy of the one from Nixpkgs repository
### (taken 2018 October).  It is used when the version of cbindgen in
### upstream nixpkgs is not up-to-date enough to compile Firefox.
{ stdenv, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  name = "rust-cbindgen-${version}";
  version = "0.6.8";

  src = fetchFromGitHub {
    owner = "eqrion";
    repo = "cbindgen";
    rev = "v${version}";
    sha256 = "0qjdccpyv3lkhnh3f5nzarbdc46hg0c6pmpj0x7sfdm22vbr85w5";
  };

  cargoSha256 = "1s12xn4xbxq422wgafxdb9nll0lk65wa6x3acicx5pj1y5ijjmmw";

  meta = with stdenv.lib; {
    description = "A project for generating C bindings from Rust code";
    homepage = https://github.com/eqrion/cbindgen;
    license = licenses.mpl20;
    maintainers = with maintainers; [ jtojnar ];
  };
}
