### NOTE: This file is a copy of the one from Nixpkgs repository
### (taken 2018 October).  It is used when the version of cbindgen in
### upstream nixpkgs is not up-to-date enough to compile Firefox.
{ stdenv, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  name = "rust-cbindgen-${version}";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "eqrion";
    repo = "cbindgen";
    rev = "v${version}";
    sha256 = "1g0vrkwkc8wsyiz04qchw07chg0mg451if02sr17s65chwmbrc19";
  };

  cargoSha256 = "1y96m2my0h8fxglxz20y68fr8mnw031pxvzjsq801gwz2p858d75";

  # https://github.com/eqrion/cbindgen/issues/338
  doCheck = false;

  # https://github.com/NixOS/nixpkgs/issues/61618
  postConfigure = ''
    touch .cargo/.package-cache
    export HOME=`pwd`
  '';

  meta = with stdenv.lib; {
    description = "A project for generating C bindings from Rust code";
    homepage = https://github.com/eqrion/cbindgen;
    license = licenses.mpl20;
    maintainers = with maintainers; [ jtojnar ];
  };
}
