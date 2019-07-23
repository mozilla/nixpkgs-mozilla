### NOTE: This file is a copy of the one from Nixpkgs repository
### (taken 2018 October).  It is used when the version of cbindgen in
### upstream nixpkgs is not up-to-date enough to compile Firefox.
{ stdenv, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  name = "rust-cbindgen-${version}";
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "eqrion";
    repo = "cbindgen";
    rev = "v${version}";
    sha256 = "1sh9kll3ky0d6chp7l7z8j91ckibxkfhi0v7imz2fgzzy2lbqy88";
  };

  cargoSha256 = "1cn84xai1n0f8xwwwwig93dawk73g1w6n6zm4axg5zl4vrmq4j6w";

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
